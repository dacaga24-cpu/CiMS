const PeakStatusService = require('../services/peakStatusService');

// Aquest controlador gestiona les peticions relacionades amb l'estat personal
// dels cims per a cada usuari. La seva funció és llegir els paràmetres de la petició,
// delegar la feina al servei i enviar la resposta HTTP amb el codi i el format adequats.
// L'identificador de l'usuari s'obté exclusivament de req.userId, que el middleware
// d'autenticació ha poblat a partir del token JWT, i mai del cos o la URL de la petició.
const PeakStatusController = {

  // Aquest mètode retorna tots els estats de cims de l'usuari autenticat.
  // Si l'usuari no ha creat cap estat, es retorna una llista buida amb codi 200.
  async listByUser(req, res, next) {
    try {
      const statuses = await PeakStatusService.getAllByUser(req.userId);
      res.status(200).json(statuses);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode retorna l'estat d'un cim concret per a l'usuari autenticat.
  // Si no existeix cap registre per a la parella usuari-cim, el servei llança un 404.
  async getByPeak(req, res, next) {
    try {
      const status = await PeakStatusService.getByPeak(req.userId, req.params.peakId);
      res.status(200).json(status);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode crea o actualitza l'estat d'un cim per a l'usuari autenticat.
  // Implementa un upsert intern: si ja existia un registre s'actualitza,
  // i si no existia es crea. Es retorna sempre el registre resultant amb codi 200,
  // tant si s'ha creat com si s'ha actualitzat, per simplicitat del client.
  async upsert(req, res, next) {
    try {
      const { isCompleted, isTarget, isFavorite } = req.body;

      const status = await PeakStatusService.upsert(
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
  async remove(req, res, next) {
    try {
      await PeakStatusService.remove(req.userId, req.params.peakId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = PeakStatusController;
