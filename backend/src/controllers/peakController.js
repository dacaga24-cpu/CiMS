const PeakService = require('../services/peakService');

function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Controlador del catàleg de cims.
const PeakController = {

  // Pàgina del catàleg amb filtres opcionals. Sense paràmetres retorna la
  // primera pàgina amb la mida per defecte definida al servei.
  async list(req, res, next) {
    try {
      const { regionId, minAltitude, maxAltitude, search, page, pageSize } = req.query;

      const result = await PeakService.getPage({
        regionId,
        minAltitude,
        maxAltitude,
        search,
        page,
        pageSize,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Cims per al mapa: camps mínims i sense paginació (justificació al servei).
  async listForMap(req, res, next) {
    try {
      const { regionId, minAltitude, maxAltitude, search } = req.query;

      const peaks = await PeakService.getForMap({
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

  // Detall d'un cim. Comprova que l'id sigui un enter positiu.
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
