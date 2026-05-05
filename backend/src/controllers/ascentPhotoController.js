const AscentPhotoService = require('../services/ascentPhotoService');

// Aquest controlador exposa les rutes del recurs ascent-photos. La seva
// responsabilitat es limita a delegar al servei i retornar la resposta HTTP.
// L'identificador de l'usuari s'obté sempre de req.userId perquè la signed
// URL ha d'estar lligada a la identitat real i mai a un valor del client.
const AscentPhotoController = {

  async createUploadUrl(req, res, next) {
    try {
      const { mimeType } = req.body || {};
      const result = await AscentPhotoService.generateUploadUrl(req.userId, {
        mimeType,
      });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AscentPhotoController;
