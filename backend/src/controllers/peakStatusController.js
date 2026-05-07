const PeakStatusService = require('../services/peakStatusService');

function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Sense aquesta validació, JS faria coerció de strings/números a booleans
// i el client podria persistir estats incorrectes enviant "true" o 1.
function ensureOptionalBoolean(value, fieldName) {
  if (value !== undefined && typeof value !== 'boolean') {
    throw badRequest(`Invalid ${fieldName}: must be a boolean`);
  }
}

// Controlador de l'estat personal dels cims. L'identificador d'usuari sempre
// surt de req.userId (poblat pel middleware d'autenticació), mai del cos
// o la URL.
const PeakStatusController = {

  // Tots els estats de l'usuari. Llista buida amb 200 si no n'ha creat cap.
  async getStatusByUser(req, res, next) {
    try {
      const statuses = await PeakStatusService.getStatusByUser(req.userId);
      res.status(200).json(statuses);
    } catch (error) {
      next(error);
    }
  },

  // Estat d'un cim concret. 404 al servei si no existeix.
  async getByUserAndPeak(req, res, next) {
    try {
      const status = await PeakStatusService.getStatusByUserAndPeak(req.userId, req.params.peakId);
      res.status(200).json(status);
    } catch (error) {
      next(error);
    }
  },

  // Upsert intern: 200 amb el registre resultant, tant si s'ha creat com
  // si s'ha actualitzat (simplifica el client).
  async upsertPeakStatus(req, res, next) {
    try {
      const { isCompleted, isTarget, isFavorite } = req.body || {};

      ensureOptionalBoolean(isCompleted, 'isCompleted');
      ensureOptionalBoolean(isTarget, 'isTarget');
      ensureOptionalBoolean(isFavorite, 'isFavorite');

      const status = await PeakStatusService.upsertPeakStatus(
        req.userId,
        req.params.peakId,
        { isCompleted, isTarget, isFavorite }
      );

      res.status(200).json(status);
    } catch (error) {
      next(error);
    }
  },

  // Elimina l'estat. 204 sense cos si tot va bé; 404 al servei si no existia.
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
