const StorageService = require('./storageService');
const { badRequest } = require('../utils/validation');

// Aquest servei resol les operacions del recurs ascent-photos exposades
// directament a l'API. La inserció de fotos a la base de dades NO viu aquí:
// va lligada a la creació d'ascensions i s'orquestra des d'ascentService
// dins d'una transacció. Aquí només es gestiona la signed URL de pujada.
const AscentPhotoService = {

  // Valida que el client ha enviat el MIME type i delega la generació de
  // la signed URL al StorageService, que és qui coneix l'estructura del
  // path al bucket i les restriccions de pujada.
  async generateUploadUrl(userId, { mimeType } = {}) {
    if (!mimeType || typeof mimeType !== 'string') {
      throw badRequest('Missing required field: mimeType');
    }

    return StorageService.generateSignedUploadUrl(userId, mimeType, 'ascents');
  },
};

module.exports = AscentPhotoService;
