const AscentPhotoService = require('../services/ascentPhotoService');

// Recurs ascent-photos. L'identificador d'usuari surt sempre de req.userId
// perquè la signed URL ha de quedar lligada a la identitat real, no a un
// valor del client.
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
