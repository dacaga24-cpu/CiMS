const AscentPhotoService = require('../services/ascentPhotoService');

// Aquest controlador gestiona les peticions relacionades amb les fotos d’ascensions.
// Totes les accions utilitzen l’usuari autenticat per protegir les dades personals.
const AscentPhotoController = {

  // Genera una URL temporal perquè el frontend pugui pujar una imatge.
  // La foto només quedarà vinculada a una ascensió quan es guardi el formulari corresponent.
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

  // Retorna la galeria paginada de fotos de l’usuari autenticat.
  // Aquesta informació permet mostrar l’historial visual d’ascensions al frontend.
  async getUserGallery(req, res, next) {
    try {
      const result = await AscentPhotoService.getUserGallery(req.userId, {
        limit: req.query.limit,
        offset: req.query.offset,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Elimina una foto d’ascensió de l’usuari autenticat.
  // El servei comprova la propietat de la foto abans d’eliminar-la de manera segura.
  async deletePhoto(req, res, next) {
    try {
      await AscentPhotoService.deletePhoto(req.userId, req.params.photoId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AscentPhotoController;