const PeakStatusService = require('../services/peakStatusService');

// Aquest mètode crea un error de validació amb codi 400.
// S'utilitza quan el cos de la petició conté camps amb un format inesperat.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest mètode comprova que un camp opcional, si s'ha enviat, sigui un boolean
// estricte. Sense aquesta validació, JavaScript faria coerció de strings o
// números a booleans i el client podria persistir estats incorrectes enviant
// per exemple "true" (string) o 1 (número) sense que es detectés l'error.
function ensureOptionalBoolean(value, fieldName) {
  if (value !== undefined && typeof value !== 'boolean') {
    throw badRequest(`Invalid ${fieldName}: must be a boolean`);
  }
}

// Aquest controlador gestiona les peticions relacionades amb l'estat personal
// dels cims per a cada usuari. La seva funció és llegir els paràmetres de la petició,
// delegar la feina al servei i enviar la resposta HTTP amb el codi i el format adequats.
// L'identificador de l'usuari s'obté exclusivament de req.userId, que el middleware
// d'autenticació ha poblat a partir del token JWT, i mai del cos o la URL de la petició.
const PeakStatusController = {

  // Aquest mètode retorna tots els estats de cims de l'usuari autenticat.
  // Si l'usuari no ha creat cap estat, es retorna una llista buida amb codi 200.
  async getStatusByUser(req, res, next) {
    try {
      const statuses = await PeakStatusService.getStatusByUser(req.userId);
      res.status(200).json(statuses);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode retorna l'estat d'un cim concret per a l'usuari autenticat.
  // Si no existeix cap registre per a la parella usuari-cim, el servei llança un 404.
  async getByUserAndPeak(req, res, next) {
    try {
      const status = await PeakStatusService.getStatusByUserAndPeak(req.userId, req.params.peakId);
      res.status(200).json(status);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode crea o actualitza l'estat d'un cim per a l'usuari autenticat.
  // Implementa un upsert intern: si ja existia un registre s'actualitza,
  // i si no existia es crea. Es retorna sempre el registre resultant amb codi 200,
  // tant si s'ha creat com si s'ha actualitzat, per simplicitat del client.
  async upsertPeakStatus(req, res, next) {
    try {
      const { isCompleted, isTarget, isFavorite } = req.body || {};

      // Els flags arriben com a booleans estrictes per garantir que el client
      // expressa la intenció de manera explícita. Si s'acceptessin valors com
      // "true" o 1, una crida amb tipus incorrectes podria persistir estats
      // erronis sense que ningú se n'adonés.
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

  // Aquest mètode elimina l'estat d'un cim per a l'usuari autenticat.
  // Si no existia cap registre, el servei llança un 404.
  // Si s'ha eliminat correctament, es respon amb 204 sense cos de resposta.
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
