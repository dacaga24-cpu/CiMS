const PeakService = require('../services/peakService');

function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest controlador gestiona les peticions relacionades amb el catàleg de cims.
// La seva funció és llegir els paràmetres de la petició, delegar la feina al servei
// i enviar la resposta HTTP amb el codi i el format adequats.
const PeakController = {

  // Aquest mètode retorna una pàgina del catàleg de cims que compleixen
  // els filtres rebuts. Els filtres i la paginació arriben per query string
  // i tots són opcionals; sense paràmetres es retorna la primera pàgina
  // del catàleg complet amb la mida per defecte definida al servei.
  //
  // `status` és un filtre que depèn de l'usuari (pendents, completats,
  // objectius, preferits). Si la petició arriba autenticada via
  // `optionalAuthMiddleware`, `req.userId` està establert i el servei
  // l'aplica; si no, el servei ignora `status` en silenci per no filtrar
  // l'estat d'autenticació a través de codes HTTP.
  async list(req, res, next) {
    try {
      const { regionId, minAltitude, maxAltitude, search, status, sortOrder, page, pageSize } = req.query;

      const result = await PeakService.getPage({
        regionId,
        minAltitude,
        maxAltitude,
        search,
        status,
        userId: req.userId,
        sortOrder,
        page,
        pageSize,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode retorna tots els cims per al mapa, amb camps mínims i
  // sense paginació. La justificació de quins camps i per què viu al servei
  // i al model; aquí només es delega.
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
