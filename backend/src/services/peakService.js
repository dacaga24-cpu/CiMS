const PeakModel = require('../models/peakModel');
const { badRequest, parseOptionalInteger } = require('../utils/validation');

// Sostre defensiu de resultats per al catàleg. Sense un límit, una cerca molt
// permissiva (per exemple un sol caràcter al filtre de nom) podria retornar
// milers de cims i carregar el navegador del client innecessàriament. Si en el
// futur cal mostrar més resultats, l'endpoint hauria d'oferir paginació
// explícita en lloc d'augmentar aquest sostre.
const MAX_PEAK_RESULTS = 500;

// Aquest servei centralitza la lògica del catàleg de cims.
// Aquí es validen els filtres rebuts, es consulten les dades a través del model
// i es gestionen els casos on el recurs sol·licitat no existeix.
const PeakService = {

  // Aquest mètode retorna la llista de cims aplicant els filtres opcionals.
  // Si algun filtre té un format incorrecte, es llança un error de validació
  // perquè el controlador respongui amb un 400 abans de consultar la base de dades.
  // Les altituds permeten 0 perquè és un valor real i útil com a límit inferior.
  async getAll({ regionId, minAltitude, maxAltitude, search } = {}) {
    const parsedRegionId = parseOptionalInteger(regionId, 'regionId');
    const parsedMinAltitude = parseOptionalInteger(minAltitude, 'minAltitude', { min: 0 });
    const parsedMaxAltitude = parseOptionalInteger(maxAltitude, 'maxAltitude', { min: 0 });

    // Aquest bloc comprova la coherència entre el mínim i el màxim d'altitud
    // per evitar consultes que mai podran retornar resultats.
    if (
      parsedMinAltitude !== undefined &&
      parsedMaxAltitude !== undefined &&
      parsedMinAltitude > parsedMaxAltitude
    ) {
      throw badRequest('minAltitude cannot be greater than maxAltitude');
    }

    return PeakModel.findAll({
      regionId: parsedRegionId,
      minAltitude: parsedMinAltitude,
      maxAltitude: parsedMaxAltitude,
      search: search ? String(search).trim() : undefined,
      limit: MAX_PEAK_RESULTS,
    });
  },

  // Aquest mètode retorna el detall d'un cim concret.
  // Si el cim no existeix, es llança un error 404 perquè la resposta HTTP
  // reflecteixi correctament que el recurs no s'ha trobat.
  async getById(id) {
    const peak = await PeakModel.findById(id);

    if (!peak) {
      const error = new Error('Peak not found');
      error.statusCode = 404;
      throw error;
    }

    return peak;
  },
};

module.exports = PeakService;
