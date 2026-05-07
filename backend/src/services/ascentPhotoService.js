const StorageService = require('./storageService');
const { badRequest } = require('../utils/validation');

// Operacions del recurs ascent-photos exposades a l'API. La inserció a BD
// NO viu aquí: va lligada a la creació d'ascensions i s'orquestra des
// d'ascentService dins d'una transacció.
const AscentPhotoService = {

  // Valida el MIME i delega al StorageService, que coneix l'estructura del
  // path al bucket i les restriccions de pujada.
  async generateUploadUrl(userId, { mimeType } = {}) {
    if (!mimeType || typeof mimeType !== 'string') {
      throw badRequest('Missing required field: mimeType');
    }

    return StorageService.generateSignedUploadUrl(userId, mimeType, 'ascents');
  },
};

module.exports = AscentPhotoService;
