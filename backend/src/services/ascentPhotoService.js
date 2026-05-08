const AscentPhotoModel = require('../models/ascentPhotoModel');
const StorageService = require('./storageService');
const { badRequest, parseOptionalInteger } = require('../utils/validation');

// Defineix quantes fotos es carreguen per defecte a la galeria.
// Aquest valor permet mostrar una primera pàgina àmplia sense fer la resposta massa pesada.
const DEFAULT_GALLERY_LIMIT = 30;

// Defineix el màxim de fotos que es poden demanar en una sola petició.
// Evita càrregues massa grans si el frontend o un client extern envia un límit excessiu.
const MAX_GALLERY_LIMIT = 60;

// Aquest servei gestiona les operacions directes sobre fotos d'ascensions.
// Inclou la generació de signed URLs de pujada i la consulta paginada de la galeria personal.
const AscentPhotoService = {

  // Genera una URL temporal perquè el frontend pugui pujar una foto al bucket.
  // La imatge encara no queda associada a cap ascensió fins que l'usuari confirma el formulari.
  async generateUploadUrl(userId, { mimeType } = {}) {
    if (!mimeType || typeof mimeType !== 'string') {
      throw badRequest('Missing required field: mimeType');
    }

    return StorageService.generateSignedUploadUrl(userId, mimeType, 'ascents');
  },

  // Retorna una pàgina de fotos de l'usuari autenticat.
  // Cada imatge inclou una URL temporal de descàrrega perquè el bucket continuï sent privat.
  async getUserGallery(userId, { limit, offset } = {}) {
    const parsedLimit = parseOptionalInteger(limit, 'limit') ??
      DEFAULT_GALLERY_LIMIT;
    const parsedOffset = parseOptionalInteger(offset, 'offset', { min: 0 }) ??
      0;

    if (parsedLimit > MAX_GALLERY_LIMIT) {
      throw badRequest(`Invalid limit: must be at most ${MAX_GALLERY_LIMIT}`);
    }

    const rows = await AscentPhotoModel.findGalleryByUserId(
      userId,
      parsedLimit + 1,
      parsedOffset
    );

    const hasMore = rows.length > parsedLimit;
    const visibleRows = rows.slice(0, parsedLimit);

    const items = await Promise.all(
      visibleRows.map(async (photo) => {
        let downloadUrl = null;

        try {
          downloadUrl = await StorageService.generateSignedDownloadUrl(
            photo.storage_path
          );
        } catch (err) {
          console.error(
            `[ascentPhotoGallery] sign download URL failed (photoId=${photo.id} path=${photo.storage_path}):`,
            err
          );
        }

        return {
          id: photo.id,
          ascentId: photo.ascent_id,
          peakId: photo.peak_id,
          peakName: photo.peak_name,
          ascentDate: photo.ascent_date,
          storagePath: photo.storage_path,
          isPrimary: photo.is_primary === 1,
          downloadUrl,
          createdAt: photo.created_at,
        };
      })
    );

    return {
      items,
      limit: parsedLimit,
      offset: parsedOffset,
      hasMore,
      nextOffset: hasMore ? parsedOffset + parsedLimit : null,
    };
  },
};

module.exports = AscentPhotoService;