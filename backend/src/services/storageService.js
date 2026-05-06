const crypto = require('crypto');
const { bucket } = require('../config/gcs');

// Aquest servei encapsula totes les operacions contra Google Cloud Storage.
// La resta del backend depèn només d'aquesta interfície i no toca mai
// directament l'API de @google-cloud/storage. Així, si en el futur cal
// canviar de proveïdor o afegir una capa de cache, només s'actualitza aquí.

// Caducitat de les signed URLs de pujada. 15 minuts és un compromís raonable:
// llarg perquè un usuari amb mala connexió pugui completar la pujada sense
// que la URL caduqui, però curt perquè una URL filtrada tingui poca utilitat
// fora de la sessió real de l'usuari que l'ha sol·licitada.
const SIGNED_UPLOAD_URL_TTL_MS = 15 * 60 * 1000;

// Caducitat per defecte de les signed URLs de descàrrega. 60 minuts és prou
// per a una sessió de visualització normal sense haver de regenerar URLs
// constantment, i prou curt perquè una URL filtrada caduqui dins d'un
// horitzó raonable. Es pot ajustar via paràmetre dins dels límits del clamp.
const DEFAULT_DOWNLOAD_TTL_MIN = 60;
const MIN_DOWNLOAD_TTL_MIN = 5;
const MAX_DOWNLOAD_TTL_MIN = 360;

// Catàleg de tipus MIME acceptats per a les fotos, amb l'extensió que es
// farà servir al path del bucket. Es manté com a whitelist explícita perquè
// acceptar qualsevol tipus permetria a un client maliciós pujar fitxers
// arbitraris (PDFs, executables) que no són imatges. L'extensió es deriva
// del MIME ja validat contra aquesta whitelist, no del nom de fitxer
// original que el client podria manipular amb caràcters d'atac (path
// traversal, etc.).
const ALLOWED_MIME_TYPES = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
};

// Mida màxima per foto. La signed URL inclou aquest límit com a constraint:
// si l'usuari intenta pujar més bytes, GCS rebutja la petició abans que
// l'objecte arribi al bucket, sense que el backend hagi de validar res.
//
// Aquest cap funciona com a safety net defensiu. La convenció acordada amb
// el frontend és que les fotos es redimensionin i comprimeixin abans de
// pujar-les, perquè el cap de 8MB no s'hauria d'arribar mai en condicions
// normals:
//
//   - Foto d'ascens: max 2048px costat llarg, qualitat JPEG ~85%, <500KB
//     objectiu.
//   - Foto de perfil: max 512px costat llarg, qualitat JPEG ~85%, <100KB
//     objectiu.
//   - HEIC ideal convertir a JPEG client-side abans de pujar perquè
//     Android no l'obre nativament i la compatibilitat web és limitada.
//
// Si el frontend no respecta aquesta convenció, la pujada no peta — només
// s'omple el bucket amb fitxers més grans del compte.
const MAX_PHOTO_SIZE_BYTES = 8 * 1024 * 1024;

// Llista de namespaces vàlids dins del bucket. Cada recurs (ascens, perfil)
// reserva un prefix propi perquè la validació de paths pugui distingir a
// quina entitat pertany cada blob i evitar que un usuari reclami fotos
// d'un namespace diferent del previst (per exemple, fer passar una foto
// d'ascens com a foto de perfil al PUT /api/users/profile-photo).
const ALLOWED_NAMESPACES = new Set(['ascents', 'profile-photos']);

// Aquesta funció valida que el namespace passat per un caller intern és
// un dels permesos. Llança un Error programàtic (sense statusCode) perquè
// és un error de codi, no d'entrada d'usuari: si arribem aquí amb un
// namespace invàlid, el problema viu al backend, no al client.
function assertNamespace(namespace) {
  if (!ALLOWED_NAMESPACES.has(namespace)) {
    throw new Error(
      `Invalid storage namespace: ${namespace}. Allowed: ${[...ALLOWED_NAMESPACES].join(', ')}`
    );
  }
}

// Prefix del path per usuari dins del bucket. El namespace permet reutilitzar
// la mateixa lògica de validació entre recursos diferents (ascents,
// profile-photos) sense duplicar codi.
function buildUserPathPrefix(userId, namespace) {
  assertNamespace(namespace);
  return `${namespace}/${userId}/`;
}

// Patró que ha de complir un storagePath complet per ser acceptat com a
// referència vàlida. Limita el nom del fitxer a un UUID v4 més una
// extensió de la whitelist, evitant path traversal i caràcters d'atac.
// El namespace s'inclou al patró perquè cada recurs valida només els
// paths del seu propi prefix.
function buildUserPathPattern(userId, namespace) {
  assertNamespace(namespace);
  const extensions = Object.values(ALLOWED_MIME_TYPES).join('|');
  return new RegExp(
    `^${namespace}/${userId}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(${extensions})$`
  );
}

const StorageService = {

  // Retorna la llista de tipus MIME acceptats. Exposat així perquè els
  // serveis que validen el payload del client no hagin de duplicar la
  // mateixa llista i puguin construir missatges d'error coherents.
  getAllowedMimeTypes() {
    return Object.keys(ALLOWED_MIME_TYPES);
  },

  // Genera una signed URL de pujada (PUT) per a un usuari concret dins
  // d'un namespace donat. El path generat inclou el userId perquè, quan
  // el client confirmi la creació del recurs i enviï el path, es pugui
  // validar que comença per `{namespace}/{userId}/`. Així es protegeix
  // contra un client que intenti reclamar fotos pujades per altres
  // usuaris o per altres recursos.
  //
  // El nom de fitxer és un UUID criptogràficament aleatori, així s'evita
  // qualsevol possibilitat d'enumeració o col·lisió.
  async generateSignedUploadUrl(userId, mimeType, namespace) {
    const extension = ALLOWED_MIME_TYPES[mimeType];
    if (!extension) {
      const error = new Error(
        `Unsupported MIME type. Allowed: ${Object.keys(ALLOWED_MIME_TYPES).join(', ')}`
      );
      error.statusCode = 400;
      throw error;
    }

    const uuid = crypto.randomUUID();
    const storagePath = `${buildUserPathPrefix(userId, namespace)}${uuid}.${extension}`;

    const [uploadUrl] = await bucket.file(storagePath).getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + SIGNED_UPLOAD_URL_TTL_MS,
      contentType: mimeType,
      // Aquest header obliga el client a no excedir la mida acordada.
      // Sense aquest límit, un client podria pujar un fitxer arbitràriament
      // gros amb el mateix permís signat i inflar el cost del bucket.
      extensionHeaders: {
        'x-goog-content-length-range': `0,${MAX_PHOTO_SIZE_BYTES}`,
      },
    });

    return {
      uploadUrl,
      storagePath,
      expiresAt: new Date(Date.now() + SIGNED_UPLOAD_URL_TTL_MS).toISOString(),
      maxSizeBytes: MAX_PHOTO_SIZE_BYTES,
      requiredHeaders: {
        'Content-Type': mimeType,
        'x-goog-content-length-range': `0,${MAX_PHOTO_SIZE_BYTES}`,
      },
    };
  },

  // Genera una signed URL de descàrrega (GET) per a un blob ja existent
  // al bucket. S'utilitza per servir les fotos al frontend sense haver
  // d'exposar el bucket públicament. El TTL s'acota al rang segur perquè
  // un caller no pugui demanar URLs efectivament permanents.
  //
  // Retorna directament la URL com a string, ja que un GET no requereix
  // headers obligatoris i el client no necessita cap metadata addicional.
  async generateSignedDownloadUrl(storagePath, ttlMinutes = DEFAULT_DOWNLOAD_TTL_MIN) {
    // Si el caller passa un valor no numèric (NaN, string, undefined),
    // Math.min/Math.max el propaguen com a NaN i la signed URL acabaria
    // amb una expiration invàlida i un error opac de la llibreria de GCS.
    // Es valida explícitament aquí perquè el problema apareix on s'origina,
    // no més tard quan ja és difícil de diagnosticar.
    if (!Number.isFinite(ttlMinutes)) {
      throw new Error(`Invalid ttlMinutes: must be a finite number (received ${ttlMinutes})`);
    }
    const clampedTtl = Math.min(
      Math.max(ttlMinutes, MIN_DOWNLOAD_TTL_MIN),
      MAX_DOWNLOAD_TTL_MIN
    );
    const [downloadUrl] = await bucket.file(storagePath).getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: Date.now() + clampedTtl * 60 * 1000,
    });
    return downloadUrl;
  },

  // Comprova si un objecte existeix realment al bucket. S'utilitza des del
  // servei d'ascents i de perfil per validar que els paths que el client
  // diu haver pujat han arribat efectivament al bucket abans d'inserir-los
  // a la base de dades. Sense aquesta comprovació, un client maliciós
  // podria registrar paths inexistents i deixar files orfes.
  //
  // Si la consulta a GCS falla per un motiu transitori (xarxa, 5xx, auth),
  // es propaga com un error amb statusCode 503 perquè el client sàpiga que
  // ha de reintentar i no es confongui amb un "no existeix" definitiu.
  async objectExists(storagePath) {
    try {
      const [exists] = await bucket.file(storagePath).exists();
      return exists;
    } catch (err) {
      const error = new Error(`Storage check failed for ${storagePath}: ${err.message}`);
      error.statusCode = 503;
      error.cause = err;
      throw error;
    }
  },

  // Esborra un objecte del bucket. S'utilitza quan s'elimina un ascens o
  // es substitueix la foto de perfil perquè els blobs corresponents no
  // quedin orfes consumint emmagatzematge. Si l'objecte ja no hi és (per
  // qualsevol motiu) GCS no llança error, així el caller no ha de gestionar
  // el cas "ja no existia" de manera especial.
  async deleteObject(storagePath) {
    await bucket.file(storagePath).delete({ ignoreNotFound: true });
  },
};

module.exports = StorageService;
module.exports.buildUserPathPrefix = buildUserPathPrefix;
module.exports.buildUserPathPattern = buildUserPathPattern;
