const AscentService = require('../services/ascentService');

// Controlador d'ascensions. L'identificador d'usuari surt sempre de
// req.userId (del JWT), mai del cos o la URL, per evitar que un client pugui
// actuar en nom d'un altre.
const AscentController = {

  // Totes les ascensions de l'usuari. Llista buida amb 200 si encara no n'ha
  // registrat cap.
  async getByUser(req, res, next) {
    try {
      const ascents = await AscentService.getByUser(req.userId);
      res.status(200).json(ascents);
    } catch (error) {
      next(error);
    }
  },

  // Ascensions de l'usuari sobre un cim concret. peakId arriba per la URL
  // i es valida al servei.
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

  // Fotos d'un ascens amb signed download URLs. El servei valida ownership.
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

  // Crea una ascensió. 201 amb el registre o 4xx si valida malament. Errors
  // de FK (peak inexistent) es propaguen com a 404 des del model.
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

  // Actualitza una ascensió. 200 amb el resultat; 404 si no existeix o és
  // d'un altre usuari.
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

  // Elimina una ascensió. 204 sense cos; 404 si no existeix o és d'un altre.
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
