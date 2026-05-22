const PeakModel = require('../models/peakModel');
const { badRequest, parseOptionalInteger } = require('../utils/validation');

// Mida per defecte de la pàgina del catàleg quan el client no la indica.
// Coincideix amb el que el frontend espera carregar a cada scroll, així el
// catàleg s'omple amb un nombre de cims que cap còmodament a la pantalla
// sense fer una sola petició massa pesada.
const DEFAULT_PAGE_SIZE = 50;

// Sostre defensiu de la mida de pàgina. Sense un màxim, un client podria
// demanar pageSize=10000 i recuperar el catàleg sencer d'un cop, anul·lant
// el propòsit de la paginació. El valor és prou alt per cobrir casos
// legítims (per exemple, una vista de taula que vulgui més registres per
// pàgina) i prou baix per limitar el cost de cada petició.
const MAX_PAGE_SIZE = 100;

// Valors acceptats per al filtre d'estat personal del catàleg. Els mantenim
// com a Set per validació O(1) i com a font de veritat única tant per al
// catàleg com per al mapa. Qualsevol altre valor és un client mal
// configurat i mereix un 400 explícit.
const ALLOWED_PEAK_STATUS_FILTERS = new Set([
    'pending',
    'completed',
    'target',
    'favorite',
]);

// Valors acceptats per a l'ordre d'altitud al catàleg. El default `desc`
// manté el comportament previ a CIMS-333 (Pica d'Estats primer). Es manté
// com a Set per validar abans d'interpolar al SQL i evitar SQL injection
// — la interpolació és necessària perquè ORDER BY no accepta paràmetres
// preparats a MySQL.
const ALLOWED_PEAK_SORT_ORDERS = new Set(['asc', 'desc']);
const DEFAULT_PEAK_SORT_ORDER = 'desc';

// Aquest mètode normalitza i valida els filtres compartits entre els tres
// punts d'entrada del catàleg (paginació, mapa i comptador). Centralitza
// la coerció per evitar que cada mètode dupliqui la mateixa lògica i que
// el contracte d'errors de validació quedi consistent.
//
// El filtre `status` és per-usuari, així que només es considera si arriba
// `userId` (vegeu `optionalAuthMiddleware`). Si arriba un valor de status
// sense usuari autenticat, l'ignorem en silenci perquè la resposta sigui
// indistingible d'una crida sense aquest paràmetre — això evita que un
// client pugui inferir l'estat d'autenticació a partir del codi HTTP.
function parseFilters({ regionId, minAltitude, maxAltitude, search, status, userId, sortOrder } = {}) {
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

    // Important: només validem el valor de `status` quan l'usuari està
    // autenticat. Per a clients anònims el descartem ABANS de tocar el
    // whitelist, garantint que `?status=favorite` i `?status=invalid`
    // produeixin exactament la mateixa resposta. Si validéssim primer i
    // descartéssim després, un atacant podria inferir el whitelist
    // comparant codis HTTP (200 vs 400) sense necessitat d'estar
    // autenticat — això viola la promesa anti-fingerprint que fa l'op.
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

    return {
        regionId: parsedRegionId,
        minAltitude: parsedMinAltitude,
        maxAltitude: parsedMaxAltitude,
        search: search ? String(search).trim() : undefined,
        status: effectiveStatus,
        userId: effectiveStatus !== undefined ? userId : undefined,
        sortOrder: parsedSortOrder,
    };
}

// Aquest servei centralitza la lògica del catàleg de cims.
// Aquí es validen els filtres rebuts, es consulten les dades a través del model
// i es gestionen els casos on el recurs sol·licitat no existeix.
const PeakService = {

    // Aquest mètode retorna una pàgina del catàleg juntament amb la
    // metadada de paginació necessària perquè el frontend pugui implementar
    // scroll infinit. Els filtres són opcionals i, sense filtres, es paginen
    // tots els cims del catàleg. Tant la pàgina com la mida es validen com
    // a enters i la mida es capa al sostre defensiu.
    async getPage({ regionId, minAltitude, maxAltitude, search, status, userId, sortOrder, page, pageSize } = {}) {
        const filters = parseFilters({ regionId, minAltitude, maxAltitude, search, status, userId, sortOrder });
        const parsedPage = parseOptionalInteger(page, 'page') ?? 1;
        const requestedPageSize = parseOptionalInteger(pageSize, 'pageSize') ?? DEFAULT_PAGE_SIZE;

        if (requestedPageSize > MAX_PAGE_SIZE) {
            throw badRequest(`Invalid pageSize: must be at most ${MAX_PAGE_SIZE}`);
        }

        const limit = requestedPageSize;
        const offset = (parsedPage - 1) * limit;

        // Es paral·lelitza la pàgina i el comptador perquè comparteixen
        // filtres però no depenen entre si, així es minimitza la latència
        // total respecte a fer-los seqüencialment.
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

    // Aquest mètode retorna tots els cims que coincideixen amb els filtres
    // amb els camps mínims que necessita el mapa. No té paginació perquè la
    // vista de mapa ha de poder mostrar el conjunt complet sense que un
    // sostre arbitrari amagui marcadors a l'usuari.
    async getForMap({ regionId, minAltitude, maxAltitude, search, status, userId } = {}) {
        const filters = parseFilters({ regionId, minAltitude, maxAltitude, search, status, userId });
        return PeakModel.findAllForMap(filters);
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
