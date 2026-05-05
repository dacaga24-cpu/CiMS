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
const SIGNED_URL_TTL_MS = 15 * 60 * 1000;

// Catàleg de tipus MIME acceptats per a les fotos d'ascensió, amb l'extensió
// que es farà servir al path del bucket. Es manté com a whitelist explícita
// perquè acceptar qualsevol tipus permetria a un client maliciós pujar
// fitxers arbitraris (PDFs, executables) que no són imatges. L'extensió es
// deriva del MIME ja validat contra aquesta whitelist, no del nom de fitxer
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
const MAX_PHOTO_SIZE_BYTES = 8 * 1024 * 1024;

// Prefix del namespace per usuari dins del bucket. Es comparteix entre la
// generació de la signed URL i la validació posterior dels storagePaths
// rebuts a la creació d'ascens, així no hi ha possibilitat de divergir
// el format si algun dia es canvia.
function buildUserPathPrefix(userId) {
  return `ascents/${userId}/`;
}

// Patró que ha de complir un storagePath complet per ser acceptat com a
// referència vàlida. Limita el nom del fitxer a un UUID v4 més una
// extensió de la whitelist, evitant path traversal i caràcters d'atac.
function buildUserPathPattern(userId) {
  const extensions = Object.values(ALLOWED_MIME_TYPES).join('|');
  return new RegExp(
    `^ascents/${userId}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(${extensions})$`
  );
}

const StorageService = {

  // Retorna la llista de tipus MIME acceptats. Exposat així perquè els
  // serveis que validen el payload del client no hagin de duplicar la
  // mateixa llista i puguin construir missatges d'error coherents.
  getAllowedMimeTypes() {
    return Object.keys(ALLOWED_MIME_TYPES);
  },

  // Genera una signed URL de pujada (PUT) per a un usuari concret. El path
  // generat inclou el userId perquè, quan el client confirmi la creació de
  // l'ascens i enviï els paths de les fotos pujades, es pugui validar que
  // cada path comença per `ascents/{userId}/`. Així es protegeix contra
  // un client que intenti reclamar fotos pujades per altres usuaris.
  //
  // El nom de fitxer és un UUID criptogràficament aleatori, així s'evita
  // qualsevol possibilitat d'enumeració o col·lisió.
  async generateSignedUploadUrl(userId, mimeType) {
    const extension = ALLOWED_MIME_TYPES[mimeType];
    if (!extension) {
      const error = new Error(
        `Unsupported MIME type. Allowed: ${Object.keys(ALLOWED_MIME_TYPES).join(', ')}`
      );
      error.statusCode = 400;
      throw error;
    }

    const uuid = crypto.randomUUID();
    const storagePath = `${buildUserPathPrefix(userId)}${uuid}.${extension}`;

    const [uploadUrl] = await bucket.file(storagePath).getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + SIGNED_URL_TTL_MS,
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
      expiresAt: new Date(Date.now() + SIGNED_URL_TTL_MS).toISOString(),
      maxSizeBytes: MAX_PHOTO_SIZE_BYTES,
      requiredHeaders: {
        'Content-Type': mimeType,
        'x-goog-content-length-range': `0,${MAX_PHOTO_SIZE_BYTES}`,
      },
    };
  },

  // Comprova si un objecte existeix realment al bucket. S'utilitza des del
  // servei d'ascents per validar que els paths que el client diu haver pujat
  // han arribat efectivament al bucket abans d'inserir-los a la base de dades.
  // Sense aquesta comprovació, un client maliciós podria registrar paths
  // inexistents i deixar files orfes a ascent_photos.
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

  // Esborra un objecte del bucket. S'utilitza quan s'elimina un ascens
  // perquè els blobs corresponents no quedin orfes consumint emmagatzematge.
  // Si l'objecte ja no hi és (per qualsevol motiu) GCS no llança error, així
  // el caller no ha de gestionar el cas "ja no existia" de manera especial.
  async deleteObject(storagePath) {
    await bucket.file(storagePath).delete({ ignoreNotFound: true });
  },
};

module.exports = StorageService;
module.exports.buildUserPathPrefix = buildUserPathPrefix;
module.exports.buildUserPathPattern = buildUserPathPattern;
