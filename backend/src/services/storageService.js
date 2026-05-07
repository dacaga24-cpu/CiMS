const crypto = require('crypto');
const { bucket } = require('../config/gcs');

// Encapsula totes les operacions contra Google Cloud Storage. La resta del
// backend no toca mai directament l'API de @google-cloud/storage.

// TTL de 15 min per a les signed URLs de pujada: prou per completar amb
// connexions lentes, prou curt perquè una URL filtrada perdi utilitat ràpid.
const SIGNED_UPLOAD_URL_TTL_MS = 15 * 60 * 1000;

// TTL per a les signed URLs de descàrrega. 60 min cobreix una sessió normal
// de visualització; el clamp evita URLs efectivament permanents.
const DEFAULT_DOWNLOAD_TTL_MIN = 60;
const MIN_DOWNLOAD_TTL_MIN = 5;
const MAX_DOWNLOAD_TTL_MIN = 360;

// Whitelist explícita de tipus MIME amb la seva extensió. Qualsevol tipus
// fora d'aquí permetria pujar fitxers arbitraris (PDFs, executables) com a
// imatges. L'extensió es deriva del MIME validat, mai del nom de fitxer
// original que el client podria manipular (path traversal).
const ALLOWED_MIME_TYPES = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
};

// Mida màxima per foto. La signed URL inclou aquest límit: GCS rebutja la
// pujada abans d'arribar al bucket, sense que el backend hagi de validar res.
//
// Funciona com a safety net. La convenció amb el frontend és redimensionar
// i comprimir abans de pujar: ascens <500KB, perfil <100KB. HEIC convé
// convertir a JPEG client-side (Android no l'obre i la web és limitada).
// Si el frontend no respecta la convenció, la pujada no peta — només
// s'omple el bucket amb fitxers més grans del compte.
const MAX_PHOTO_SIZE_BYTES = 8 * 1024 * 1024;

// Namespaces vàlids dins del bucket. Cada recurs reserva un prefix propi
// perquè un usuari no pugui reclamar fotos d'un namespace diferent del
// previst (per exemple, fer passar una foto d'ascens com a foto de perfil).
const ALLOWED_NAMESPACES = new Set(['ascents', 'profile-photos']);

// Llança un Error programàtic (sense statusCode) perquè un namespace invàlid
// és bug intern del backend, no entrada d'usuari.
function assertNamespace(namespace) {
  if (!ALLOWED_NAMESPACES.has(namespace)) {
    throw new Error(
      `Invalid storage namespace: ${namespace}. Allowed: ${[...ALLOWED_NAMESPACES].join(', ')}`
    );
  }
}

// Prefix del path per usuari dins del bucket.
function buildUserPathPrefix(userId, namespace) {
  assertNamespace(namespace);
  return `${namespace}/${userId}/`;
}

// Patró que ha de complir un storagePath complet: UUID v4 + extensió de la
// whitelist dins del namespace de l'usuari. Tanca path traversal i caràcters
// d'atac al validar paths que el client envia.
function buildUserPathPattern(userId, namespace) {
  assertNamespace(namespace);
  const extensions = Object.values(ALLOWED_MIME_TYPES).join('|');
  return new RegExp(
    `^${namespace}/${userId}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(${extensions})$`
  );
}

const StorageService = {

  // Llista de MIMEs acceptats, exposada perquè els serveis que validen el
  // payload no hagin de duplicar-la.
  getAllowedMimeTypes() {
    return Object.keys(ALLOWED_MIME_TYPES);
  },

  // Genera una signed URL de pujada (PUT). El path inclou userId i un UUID
  // criptogràficament aleatori, així el client pot reclamar-lo després via
  // pathPattern sense que pugui apuntar a fotos d'altres usuaris ni endevinar-les.
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
      // Obliga el client a no excedir la mida acordada: sense aquest header
      // podria pujar un fitxer arbitràriament gros amb la mateixa firma.
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

  // Genera una signed URL de descàrrega (GET) amb TTL acotat al rang segur.
  // Retorna directament la URL com a string.
  async generateSignedDownloadUrl(storagePath, ttlMinutes = DEFAULT_DOWNLOAD_TTL_MIN) {
    // Si el caller passa un valor no numèric, Math.min/Math.max el propaguen
    // com a NaN i la URL acabaria amb una expiration invàlida i un error
    // opac de la llibreria de GCS. Es valida aquí per veure el problema
    // on s'origina.
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

  // Comprova si un objecte existeix al bucket. S'usa per validar que els
  // paths que el client diu haver pujat hi són abans d'inserir-los a la BD;
  // sense això, un client maliciós podria deixar files orfes. Un fallo
  // transitori es propaga amb statusCode 503 perquè el client pugui
  // reintentar i no es confongui amb un "no existeix" definitiu.
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

  // Esborra un objecte del bucket. ignoreNotFound fa que el caller no hagi
  // de gestionar el cas "ja no existia" de manera especial.
  async deleteObject(storagePath) {
    await bucket.file(storagePath).delete({ ignoreNotFound: true });
  },
};

module.exports = StorageService;
module.exports.buildUserPathPrefix = buildUserPathPrefix;
module.exports.buildUserPathPattern = buildUserPathPattern;
