const AscentService = require('../services/ascentService');

// Aquest controlador gestiona les peticions relacionades amb les ascensions.
// Garanteix que totes les operacions es facin sobre l’usuari autenticat.
const AscentController = {

  // Retorna l’historial complet d’ascensions de l’usuari.
  // Si encara no n’ha registrat cap, es retorna una llista buida.
  async getByUser(req, res, next) {
    try {
      const ascents = await AscentService.getByUser(req.userId);
      res.status(200).json(ascents);
    } catch (error) {
      next(error);
    }
  },

  // Retorna les ascensions de l’usuari associades a un cim concret.
  // El cim es rep des de la URL i el servei en valida la informació.
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

  // Retorna les fotos associades a una ascensió concreta.
  // El servei comprova que l’ascensió pertanyi a l’usuari autenticat.
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

  // Afegeix fotos a una ascensió existent de l’usuari.
  // Les imatges ja han d’estar pujades i el servei valida que siguin correctes.
  async addPhotosToAscent(req, res, next) {
    try {
      const { photos } = req.body || {};

      const createdPhotos = await AscentService.addPhotosToAscent(
        req.userId,
        req.params.ascentId,
        photos,
      );

      res.status(201).json(createdPhotos);
    } catch (error) {
      next(error);
    }
  },

  // Crea una ascensió manual per a l’usuari autenticat.
  // Pot incloure la data, les notes i les fotos associades.
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
  // Aquest flux aporta més fiabilitat perquè vincula l’ascensió amb una posició real.
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

  // Actualitza una ascensió existent de l’usuari autenticat.
  // El servei valida que el registre existeixi i que pertanyi al mateix usuari.
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

  // Elimina una ascensió de l’usuari autenticat.
  // Aquesta acció permet mantenir l’historial personal corregit i actualitzat.
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