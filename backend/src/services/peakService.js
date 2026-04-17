const PeakModel = require('../models/peakModel');

// Aquest mètode crea un error de validació amb codi 400.
// S'utilitza quan els filtres rebuts no compleixen el format esperat.
function badRequest(message) {
    const error = new Error(message);
    error.statusCode = 400;
    return error;
}

// Aquest mètode converteix un valor rebut en un enter positiu.
// Retorna null si el valor no es pot interpretar com un enter vàlid,
// i d'aquesta manera permet detectar filtres mal formats.
function parsePositiveInteger(value) {
    if (value === undefined || value === null || value === '') {
        return undefined;
    }
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 0) {
        return null;
    }
    return parsed;
}

// Aquest servei centralitza la lògica del catàleg de cims.
// Aquí es validen els filtres rebuts, es consulten les dades a través del model
// i es gestionen els casos on el recurs sol·licitat no existeix.
const PeakService = {

    // Aquest mètode retorna la llista de cims aplicant els filtres opcionals.
    // Si algun filtre té un format incorrecte, es llança un error de validació
    // perquè el controlador respongui amb un 400 abans de consultar la base de dades.
    async getAll({ regionId, minAltitude, maxAltitude, search } = {}) {
        const parsedRegionId = parsePositiveInteger(regionId);
        const parsedMinAltitude = parsePositiveInteger(minAltitude);
        const parsedMaxAltitude = parsePositiveInteger(maxAltitude);

        if (parsedRegionId === null) {
            throw badRequest('Invalid regionId: must be a positive integer');
        }
        if (parsedMinAltitude === null) {
            throw badRequest('Invalid minAltitude: must be a positive integer');
        }
        if (parsedMaxAltitude === null) {
            throw badRequest('Invalid maxAltitude: must be a positive integer');
        }

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