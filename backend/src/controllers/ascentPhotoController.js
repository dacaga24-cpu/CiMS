const AscentPhotoService = require('../services/ascentPhotoService');

// Aquest controlador gestiona les peticions relacionades amb fotos d'ascensions.
// Totes les accions treballen amb l'usuari autenticat, sense acceptar userId des del client.
const AscentPhotoController = {

  // Retorna una URL temporal perquè el frontend pugui pujar una imatge al bucket.
  // Aquesta imatge encara no queda vinculada a cap ascensió fins que es desa el formulari.
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

  // Retorna la galeria paginada de fotos de l'usuari autenticat.
  // Aquesta resposta alimentarà la pantalla completa de galeria del frontend.
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

  // Elimina una foto d'ascensió de l'usuari autenticat.
  // El servei comprova que la foto pertanyi realment a l'usuari abans
  // d'esborrar-la de la base de dades i intentar eliminar-la del bucket.
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