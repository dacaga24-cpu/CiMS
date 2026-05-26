const PeakModel = require('../models/peakModel');
const { badRequest, parseOptionalInteger } = require('../utils/validation');

// Defineix la mida per defecte de cada pàgina del catàleg.
// Permet carregar un nombre equilibrat de cims sense fer respostes massa pesades.
const DEFAULT_PAGE_SIZE = 50;

// Defineix el màxim de cims que es poden demanar en una sola pàgina.
// Evita peticions excessives i manté controlat el cost de la consulta.
const MAX_PAGE_SIZE = 100;

// Defineix els valors acceptats per filtrar cims segons l’estat personal.
// Aquest conjunt permet validar el filtre abans d’enviar-lo al model.
const ALLOWED_PEAK_STATUS_FILTERS = new Set([
    'pending',
    'completed',
    'target',
    'favorite',
]);

// Defineix els valors acceptats per ordenar el catàleg.
// Aquests valors es validen perquè després s’utilitzen dins de la consulta SQL.
const ALLOWED_PEAK_SORT_ORDERS = new Set(['asc', 'desc']);
const DEFAULT_PEAK_SORT_ORDER = 'desc';
const ALLOWED_PEAK_SORT_BY = new Set(['altitude', 'name']);
const DEFAULT_PEAK_SORT_BY = 'altitude';

// Aquest mètode normalitza i valida els filtres del catàleg.
// Centralitza el tractament de cerca, altitud, estat personal i ordenació.
function parseFilters({ regionId, minAltitude, maxAltitude, search, status, userId, sortBy, sortOrder } = {}) {
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

    // El filtre d’estat només s’aplica quan hi ha usuari autenticat.
    // Si no hi ha sessió, es manté el comportament públic del catàleg.
    const hasIdentity = userId !== undefined && userId !== null;
    let effectiveStatus;
    if (hasIdentity && status !== undefined && status !== null && status !== '') {
        const normalizedStatus = String(status).trim().toLowerCase();
        if (!ALLOWED_PEAK_STATUS_FILTERS.has(normalizedStatus)) {
            throw badRequest(
                `Invalid status: must be one of ${[...ALLOWED_PEAK_STATUS_FILTERS].join(', ')}`,
            );
        }
        effectiveStatus = normalizedStatus;
    }

    let parsedSortOrder = DEFAULT_PEAK_SORT_ORDER;
    if (sortOrder !== undefined && sortOrder !== null && sortOrder !== '') {
        const normalizedSortOrder = String(sortOrder).trim().toLowerCase();
        if (!ALLOWED_PEAK_SORT_ORDERS.has(normalizedSortOrder)) {
            throw badRequest(
                `Invalid sortOrder: must be one of ${[...ALLOWED_PEAK_SORT_ORDERS].join(', ')}`,
            );
        }
        parsedSortOrder = normalizedSortOrder;
    }

    let parsedSortBy = DEFAULT_PEAK_SORT_BY;
    if (sortBy !== undefined && sortBy !== null && sortBy !== '') {
        const normalizedSortBy = String(sortBy).trim().toLowerCase();
        if (!ALLOWED_PEAK_SORT_BY.has(normalizedSortBy)) {
            throw badRequest(
                `Invalid sortBy: must be one of ${[...ALLOWED_PEAK_SORT_BY].join(', ')}`,
            );
        }
        parsedSortBy = normalizedSortBy;
    }

    return {
        regionId: parsedRegionId,
        minAltitude: parsedMinAltitude,
        maxAltitude: parsedMaxAltitude,
        search: search ? String(search).trim() : undefined,
        status: effectiveStatus,
        userId: effectiveStatus !== undefined ? userId : undefined,
        sortBy: parsedSortBy,
        sortOrder: parsedSortOrder,
    };
}

// Aquest servei centralitza la lògica del catàleg de cims.
// Valida els filtres, consulta el model i gestiona els casos en què un cim no existeix.
const PeakService = {

    // Retorna una pàgina del catàleg amb la informació de paginació.
    // Aquesta resposta permet al frontend mostrar resultats filtrats i controlar el scroll o les pàgines.
    async getPage({ regionId, minAltitude, maxAltitude, search, status, userId, sortBy, sortOrder, page, pageSize } = {}) {
        const filters = parseFilters({ regionId, minAltitude, maxAltitude, search, status, userId, sortBy, sortOrder });
        const parsedPage = parseOptionalInteger(page, 'page') ?? 1;
        const requestedPageSize = parseOptionalInteger(pageSize, 'pageSize') ?? DEFAULT_PAGE_SIZE;

        if (requestedPageSize > MAX_PAGE_SIZE) {
            throw badRequest(`Invalid pageSize: must be at most ${MAX_PAGE_SIZE}`);
        }

        const limit = requestedPageSize;
        const offset = (parsedPage - 1) * limit;

        // Aquestes consultes es fan en paral·lel perquè la llista i el total no depenen entre si.
        // Això redueix el temps necessari per construir la resposta del catàleg.
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

    // Retorna els cims necessaris per mostrar-los al mapa.
    // No aplica paginació perquè el mapa ha de representar tots els resultats filtrats.
    async getForMap({ regionId, minAltitude, maxAltitude, search, status, userId } = {}) {
        const filters = parseFilters({ regionId, minAltitude, maxAltitude, search, status, userId });
        return PeakModel.findAllForMap(filters);
    },

    // Retorna el detall d’un cim concret.
    // Si el cim no existeix, genera un error perquè el client pugui mostrar el cas correctament.
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