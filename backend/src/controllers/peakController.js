const PeakService = require('../services/peakService');

// Aquest mètode crea un error de validació amb codi 400.
// S'utilitza quan l'identificador rebut a la URL no té un format vàlid.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest controlador gestiona les peticions relacionades amb el catàleg de cims.
// La seva funció és llegir els paràmetres de la petició, delegar la feina al servei
// i enviar la resposta HTTP amb el codi i el format adequats.
const PeakController = {

  // Aquest mètode retorna la llista de cims que compleixen els filtres rebuts.
  // Els filtres arriben per query string i són tots opcionals,
  // de manera que sense filtres es retorna el catàleg complet.
  async list(req, res, next) {
    try {
      const { regionId, minAltitude, maxAltitude, search } = req.query;

      const peaks = await PeakService.getAll({
        regionId,
        minAltitude,
        maxAltitude,
        search,
      });

      res.status(200).json(peaks);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode retorna el detall d'un cim concret a partir del seu identificador.
  // Comprova que l'identificador sigui un enter vàlid abans de consultar el servei.
  async getById(req, res, next) {
    try {
      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id <= 0) {
        throw badRequest('Invalid peak id');
      }

      const peak = await PeakService.getById(id);
      res.status(200).json(peak);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = PeakController;
