const PeakStatusService = require('../services/peakStatusService');

// Aquest mètode crea un error de validació amb codi 400.
// S’utilitza quan el cos de la petició conté dades incorrectes.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest mètode valida que un camp opcional sigui un booleà quan s’envia.
// Ajuda a evitar que es guardin estats incorrectes per valors amb formats no esperats.
function ensureOptionalBoolean(value, fieldName) {
  if (value !== undefined && typeof value !== 'boolean') {
    throw badRequest(`Invalid ${fieldName}: must be a boolean`);
  }
}

// Aquest controlador gestiona les peticions relacionades amb l’estat personal dels cims.
// Totes les operacions utilitzen l’usuari autenticat per protegir la informació de cada compte.
const PeakStatusController = {

  // Retorna tots els estats de cims de l’usuari autenticat.
  // Si l’usuari encara no ha marcat cap cim, es retorna una llista buida.
  async getStatusByUser(req, res, next) {
    try {
      const statuses = await PeakStatusService.getStatusByUser(req.userId);
      res.status(200).json(statuses);
    } catch (error) {
      next(error);
    }
  },

  // Retorna l’estat personal d’un cim concret per a l’usuari autenticat.
  // Aquesta informació permet saber si el cim és objectiu, favorit o completat.
  async getByUserAndPeak(req, res, next) {
    try {
      const status = await PeakStatusService.getStatusByUserAndPeak(req.userId, req.params.peakId);
      res.status(200).json(status);
    } catch (error) {
      next(error);
    }
  },

  // Crea o actualitza l’estat manual d’un cim per a l’usuari autenticat.
  // Només permet modificar objectiu i favorit, perquè l’estat completat depèn de les ascensions registrades.
  async upsertPeakStatus(req, res, next) {
    try {
      const body = req.body || {};
      const { isTarget, isFavorite } = body;

      if (Object.prototype.hasOwnProperty.call(body, 'isCompleted')) {
        throw badRequest('Completed status is derived from ascents and cannot be updated manually');
      }

      // Aquesta validació assegura que els estats manuals arribin amb un valor clar i explícit.
      // Això evita guardar informació amb formats incorrectes.
      ensureOptionalBoolean(isTarget, 'isTarget');
      ensureOptionalBoolean(isFavorite, 'isFavorite');

      const status = await PeakStatusService.upsertPeakStatus(
        req.userId,
        req.params.peakId,
        { isTarget, isFavorite }
      );

      res.status(200).json(status);
    } catch (error) {
      next(error);
    }
  },

  // Elimina l’estat personal d’un cim per a l’usuari autenticat.
  // Aquesta acció permet desfer la relació manual entre l’usuari i el cim.
  async removeByUserAndPeak(req, res, next) {
    try {
      await PeakStatusService.removeByUserAndPeak(req.userId, req.params.peakId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = PeakStatusController;