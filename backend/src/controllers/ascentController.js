const AscentService = require('../services/ascentService');

// Aquest controlador gestiona les peticions HTTP relacionades amb les ascensions.
// L’usuari sempre s’obté del token validat pel middleware, evitant que el client
// pugui actuar sobre dades d’un altre compte.
const AscentController = {

  // Retorna totes les ascensions de l'usuari autenticat.
  // Sempre 200, amb llista buida si l'usuari encara no n'ha registrat cap.
  async getByUser(req, res, next) {
    try {
      const ascents = await AscentService.getByUser(req.userId);
      res.status(200).json(ascents);
    } catch (error) {
      next(error);
    }
  },

  // Retorna les ascensions de l'usuari autenticat sobre un cim concret.
  // El peakId arriba per la URL i es valida al servei.
  async getByUserAndPeak(req, res, next) {
    try {
      const ascents = await AscentService.getByUserAndPeak(
        req.userId,
        req.params.peakId,
      );
      res.status(200).json(ascents);
    } catch (error) {
      next(error);
    }
  },

  // Retorna totes les fotos d'un ascens concret amb signed download URLs.
  // El servei valida que l'ascensió pertanyi a l'usuari autenticat.
  async getPhotosForAscent(req, res, next) {
    try {
      const photos = await AscentService.getPhotosForAscent(
        req.userId,
        req.params.ascentId,
      );
      res.status(200).json(photos);
    } catch (error) {
      next(error);
    }
  },

  // Crea una ascensió manual per a l'usuari autenticat.
  // Pot incloure data, notes i fotos ja pujades al bucket.
  async create(req, res, next) {
    try {
      const { peakId, ascentDate, notes, photos } = req.body || {};

      const ascent = await AscentService.create(req.userId, {
        peakId,
        ascentDate,
        notes,
        photos,
      });

      res.status(201).json(ascent);
    } catch (error) {
      next(error);
    }
  },

  // Crea una ascensió verificada amb la ubicació capturada pel dispositiu.
  // La data queda vinculada al moment real de captura i no es podrà editar.
  async createVerified(req, res, next) {
    try {
      const {
        peakId,
        notes,
        photos,
        capturedLatitude,
        capturedLongitude,
        capturedAccuracyMeters,
        capturedAt,
      } = req.body || {};

      const ascent = await AscentService.createVerifiedFromDeviceLocation(
        req.userId,
        {
          peakId,
          notes,
          photos,
          capturedLatitude,
          capturedLongitude,
          capturedAccuracyMeters,
          capturedAt,
        }
      );

      res.status(201).json(ascent);
    } catch (error) {
      next(error);
    }
  },

  // Actualitza una ascensió existent de l'usuari autenticat.
  // Si no existeix o no pertany a l'usuari, el servei respon amb 404.
  async update(req, res, next) {
    try {
      const { peakId, ascentDate, notes } = req.body || {};

      const ascent = await AscentService.update(
        req.userId,
        req.params.ascentId,
        { peakId, ascentDate, notes },
      );

      res.status(200).json(ascent);
    } catch (error) {
      next(error);
    }
  },

  // Elimina una ascensió de l'usuari autenticat.
  // Si tot va bé, retorna 204 sense cos.
  async remove(req, res, next) {
    try {
      await AscentService.remove(req.userId, req.params.ascentId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AscentController;