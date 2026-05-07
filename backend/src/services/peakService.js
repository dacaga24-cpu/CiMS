const PeakModel = require('../models/peakModel');
const { badRequest, parseOptionalInteger } = require('../utils/validation');

const DEFAULT_PAGE_SIZE = 50;

// Sostre defensiu: sense màxim, un client podria demanar pageSize=10000 i
// recuperar el catàleg sencer, anul·lant la paginació.
const MAX_PAGE_SIZE = 100;

// Normalitza i valida els filtres compartits entre paginació, mapa i comptador.
function parseFilters({ regionId, minAltitude, maxAltitude, search } = {}) {
    const parsedRegionId = parseOptionalInteger(regionId, 'regionId');
    const parsedMinAltitude = parseOptionalInteger(minAltitude, 'minAltitude', { min: 0 });
    const parsedMaxAltitude = parseOptionalInteger(maxAltitude, 'maxAltitude', { min: 0 });

    if (
        parsedMinAltitude !== undefined &&
        parsedMaxAltitude !== undefined &&
        parsedMinAltitude > parsedMaxAltitude
    ) {
        throw badRequest('minAltitude cannot be greater than maxAltitude');
    }

    return {
        regionId: parsedRegionId,
        minAltitude: parsedMinAltitude,
        maxAltitude: parsedMaxAltitude,
        search: search ? String(search).trim() : undefined,
    };
}

// Lògica del catàleg de cims.
const PeakService = {

    // Pàgina del catàleg amb metadada de paginació per al scroll infinit.
    // pageSize es capa al sostre defensiu.
    async getPage({ regionId, minAltitude, maxAltitude, search, page, pageSize } = {}) {
        const filters = parseFilters({ regionId, minAltitude, maxAltitude, search });
        const parsedPage = parseOptionalInteger(page, 'page') ?? 1;
        const requestedPageSize = parseOptionalInteger(pageSize, 'pageSize') ?? DEFAULT_PAGE_SIZE;

        if (requestedPageSize > MAX_PAGE_SIZE) {
            throw badRequest(`Invalid pageSize: must be at most ${MAX_PAGE_SIZE}`);
        }

        const limit = requestedPageSize;
        const offset = (parsedPage - 1) * limit;

        // Pàgina i comptador en paral·lel: comparteixen filtres però no
        // depenen entre si.
        const [items, totalItems] = await Promise.all([
            PeakModel.findAll({ ...filters, limit, offset }),
            PeakModel.count(filters),
        ]);

        const totalPages = totalItems === 0 ? 0 : Math.ceil(totalItems / limit);

        return {
            items,
            pagination: {
                page: parsedPage,
                pageSize: limit,
                totalItems,
                totalPages,
                hasMore: parsedPage < totalPages,
            },
        };
    },

    // Cims per al mapa amb filtres però sense paginació (la vista mostra el
    // conjunt complet).
    async getForMap({ regionId, minAltitude, maxAltitude, search } = {}) {
        const filters = parseFilters({ regionId, minAltitude, maxAltitude, search });
        return PeakModel.findAllForMap(filters);
    },

    // Detall d'un cim. 404 si no existeix.
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
