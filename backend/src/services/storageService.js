const crypto = require('crypto');
const { bucket } = require('../config/gcs');

// Aquest servei centralitza les operacions amb Google Cloud Storage.
// Permet generar URLs temporals, validar fitxers i eliminar imatges sense exposar directament el bucket.
const SIGNED_UPLOAD_URL_TTL_MS = 15 * 60 * 1000;

// Defineix la durada de les URLs temporals de descàrrega.
// El rang evita URLs massa curtes o excessivament persistents.
const DEFAULT_DOWNLOAD_TTL_MIN = 60;
const MIN_DOWNLOAD_TTL_MIN = 5;
const MAX_DOWNLOAD_TTL_MIN = 360;

// Defineix els tipus d’imatge acceptats i l’extensió corresponent.
// Aquesta llista evita que es puguin pujar fitxers no previstos com a fotos.
const ALLOWED_MIME_TYPES = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
};

// Defineix la mida màxima permesa per a cada foto.
// Aquest límit ajuda a controlar l’ús d’emmagatzematge i evita pujades excessives.
const MAX_PHOTO_SIZE_BYTES = 8 * 1024 * 1024;

// Defineix els espais vàlids dins del bucket.
// Cada tipus de recurs utilitza el seu propi prefix per mantenir les imatges separades.
const ALLOWED_NAMESPACES = new Set(['ascents', 'profile-photos']);

// Valida que el namespace utilitzat sigui un dels permesos.
// Si no ho és, indica un error intern en l’ús del servei.
function assertNamespace(namespace) {
  if (!ALLOWED_NAMESPACES.has(namespace)) {
    throw new Error(
      `Invalid storage namespace: ${namespace}. Allowed: ${[...ALLOWED_NAMESPACES].join(', ')}`
    );
  }
}

// Construeix el prefix de carpeta d’un usuari dins del bucket.
// Permet ubicar cada imatge dins del seu recurs i del seu propietari.
function buildUserPathPrefix(userId, namespace) {
  assertNamespace(namespace);
  return `${namespace}/${userId}/`;
}

// Construeix el patró que ha de complir una ruta d’imatge vàlida.
// Serveix per comprovar que un fitxer pertany a l’usuari i al recurs correcte.
function buildUserPathPattern(userId, namespace) {
  assertNamespace(namespace);
  const extensions = Object.values(ALLOWED_MIME_TYPES).join('|');
  return new RegExp(
    `^${namespace}/${userId}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(${extensions})$`
  );
}

const StorageService = {

  // Retorna els tipus MIME acceptats pel servei.
  // Permet reutilitzar la mateixa llista de formats en altres validacions.
  getAllowedMimeTypes() {
    return Object.keys(ALLOWED_MIME_TYPES);
  },

  // Genera una URL temporal perquè l’usuari pugui pujar una imatge.
  // També retorna la ruta on quedarà guardada per poder vincular-la després al recurs corresponent.
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
      // Aquest límit s’inclou a la pujada perquè el bucket rebutgi fitxers massa grans.
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

  // Genera una URL temporal de descàrrega per a una imatge privada.
  // Això permet mostrar fotos al frontend sense fer públic el bucket.
  async generateSignedDownloadUrl(storagePath, ttlMinutes = DEFAULT_DOWNLOAD_TTL_MIN) {
    // Aquesta validació evita generar URLs amb una caducitat incorrecta.
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

  // Comprova si una imatge existeix realment al bucket.
  // S’utilitza abans de guardar una ruta a la base de dades per evitar referències inexistents.
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

  // Elimina una imatge del bucket.
  // S’utilitza quan s’esborren o se substitueixen fotos per evitar fitxers orfes.
  async deleteObject(storagePath) {
    await bucket.file(storagePath).delete({ ignoreNotFound: true });
  },
};

module.exports = StorageService;
module.exports.buildUserPathPrefix = buildUserPathPrefix;
module.exports.buildUserPathPattern = buildUserPathPattern;