const PeakService = require('../services/peakService');

// Aquest mètode crea un error de validació amb codi 400.
// S’utilitza quan algun paràmetre rebut no és vàlid.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest controlador gestiona les peticions relacionades amb el catàleg de cims.
// Llegeix els paràmetres rebuts, delega la lògica al servei i retorna la resposta adequada.
const PeakController = {

  // Retorna una pàgina del catàleg de cims segons els filtres rebuts.
  // Permet aplicar cerca, filtratge, ordenació i paginació de manera centralitzada.
  async list(req, res, next) {
    try {
      const { regionId, minAltitude, maxAltitude, search, status, sortBy, sortOrder, page, pageSize } = req.query;

      const result = await PeakService.getPage({
        regionId,
        minAltitude,
        maxAltitude,
        search,
        status,
        userId: req.userId,
        sortBy,
        sortOrder,
        page,
        pageSize,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Retorna els cims necessaris per mostrar-los al mapa.
  // Aquesta resposta evita la paginació perquè el mapa necessita representar tots els resultats filtrats.
  async listForMap(req, res, next) {
    try {
      const { regionId, minAltitude, maxAltitude, search, status } = req.query;

      const peaks = await PeakService.getForMap({
        regionId,
        minAltitude,
        maxAltitude,
        search,
        status,
        userId: req.userId,
      });

      res.status(200).json(peaks);
    } catch (error) {
      next(error);
    }
  },

  // Retorna el detall d’un cim concret.
  // L’identificador es valida abans de consultar el servei per evitar peticions incorrectes.
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