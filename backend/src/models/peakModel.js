const pool = require('../config/db');

// Aquest model centralitza l’accés a les dades dels cims.
// Permet consultar el catàleg, aplicar filtres i afegir les comarques associades.
const PEAK_STATUS_CONDITION = Object.freeze({
    completed: 'COALESCE(ps.is_completed, 0) = 1',
    target: 'COALESCE(ps.is_target, 0) = 1',
    favorite: 'COALESCE(ps.is_favorite, 0) = 1',
    pending: 'COALESCE(ps.is_completed, 0) = 0',
});

// Aquesta constant defineix el bucket utilitzat per construir les imatges públiques dels cims.
// Permet separar les fotos del catàleg de la resta d’imatges si l’entorn ho configura.
const peakPhotosBucketName = process.env.PEAK_PHOTOS_BUCKET_NAME || process.env.GCS_BUCKET_NAME;

// Aquesta consulta afegeix una única foto pública a cada cim.
// Evita duplicats si en el futur un cim pot tenir més d’una imatge associada.
const PEAK_PHOTO_JOIN = `
    LEFT JOIN (
        SELECT pp.peak_id, pp.storage_path
        FROM peak_photos pp
        INNER JOIN (
            SELECT peak_id, MIN(id) AS id
            FROM peak_photos
            GROUP BY peak_id
        ) first_photo ON first_photo.id = pp.id
    ) pp ON pp.peak_id = p.id
`;

// Construeix una URL pública a partir de la ruta interna de la imatge.
// Això permet que el frontend pugui mostrar la foto directament.
function buildPublicImageUrl(storagePath) {
    if (!storagePath || !peakPhotosBucketName) {
        return null;
    }

    const encodedPath = storagePath
        .split('/')
        .map(encodeURIComponent)
        .join('/');

    return `https://storage.googleapis.com/${peakPhotosBucketName}/${encodedPath}`;
}

// Adapta una fila de base de dades al format que consumeix el frontend.
// També converteix la ruta de la foto en una URL pública.
function mapPeakRow(row) {
    return {
        id: row.id,
        name: row.name,
        altitude: row.altitude,
        latitude: row.latitude,
        longitude: row.longitude,
        description: row.description,
        imageUrl: buildPublicImageUrl(row.photo_storage_path),
    };
}

// Construeix els filtres comuns del catàleg.
// S’utilitza per mantenir el mateix criteri a la llista, el mapa i el comptador.
function buildPeakFilters({ regionId, minAltitude, maxAltitude, search, status, userId } = {}) {
    const joinClauses = [];
    const joinParams = [];
    const conditions = [];
    const whereParams = [];

    if (regionId !== undefined && regionId !== null) {
        joinClauses.push('INNER JOIN peak_regions pr ON pr.peak_id = p.id');
        conditions.push('pr.region_id = ?');
        whereParams.push(regionId);
    }

    // Aquest filtre aplica l’estat personal del cim només quan hi ha usuari autenticat.
    // Permet cercar cims completats, pendents, objectiu o favorits.
    if (status !== undefined && status !== null && userId !== undefined) {
        const statusCondition = PEAK_STATUS_CONDITION[status];
        if (!statusCondition) {
            throw new Error(`Unhandled peak status filter at model layer: ${status}`);
        }

        joinClauses.push(
            'LEFT JOIN peak_status ps ON ps.peak_id = p.id AND ps.user_id = ?',
        );
        joinParams.push(userId);
        conditions.push(statusCondition);
    }

    if (minAltitude !== undefined && minAltitude !== null) {
        conditions.push('p.altitude >= ?');
        whereParams.push(minAltitude);
    }

    if (maxAltitude !== undefined && maxAltitude !== null) {
        conditions.push('p.altitude <= ?');
        whereParams.push(maxAltitude);
    }

    if (search) {
        conditions.push('p.name LIKE ?');
        whereParams.push(`%${search}%`);
    }

    const join = joinClauses.length > 0 ? ' ' + joinClauses.join(' ') + ' ' : '';
    const where = conditions.length > 0 ? ' WHERE ' + conditions.join(' AND ') : '';
    return { join, where, joinParams, whereParams };
}

// Afegeix les comarques corresponents a una llista de cims.
// Fa una sola consulta agrupada per evitar una petició independent per cada cim.
async function attachRegionsToPeaks(peaks) {
    if (peaks.length === 0) {
        return peaks;
    }

    const peakIds = peaks.map((peak) => peak.id);
    const placeholders = peakIds.map(() => '?').join(', ');
    const sql = `
        SELECT pr.peak_id, r.id, r.name
        FROM peak_regions pr
        INNER JOIN regions r ON r.id = pr.region_id
        WHERE pr.peak_id IN (${placeholders})
        ORDER BY r.name ASC
    `;

    const [rows] = await pool.execute(sql, peakIds);

    const regionsByPeakId = new Map();
    for (const row of rows) {
        if (!regionsByPeakId.has(row.peak_id)) {
            regionsByPeakId.set(row.peak_id, []);
        }
        regionsByPeakId.get(row.peak_id).push({ id: row.id, name: row.name });
    }

    for (const peak of peaks) {
        peak.regions = regionsByPeakId.get(peak.id) || [];
    }

    return peaks;
}

const PeakModel = {

    // Retorna una pàgina de cims segons els filtres, l’ordenació i la paginació rebuts.
    // Aquesta consulta alimenta el catàleg principal del frontend.
    async findAll({ regionId, minAltitude, maxAltitude, search, status, userId, sortBy, sortOrder, limit, offset } = {}) {
        const { join, where, joinParams, whereParams } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search, status, userId,
        });

        // Aquesta validació garanteix que l’ordenació només utilitzi valors permesos.
        // És important perquè aquests camps s’incorporen directament a la consulta SQL.
        if (sortOrder !== 'asc' && sortOrder !== 'desc') {
            throw new Error(`Unhandled sortOrder at model layer: ${sortOrder}`);
        }
        if (sortBy !== 'altitude' && sortBy !== 'name') {
            throw new Error(`Unhandled sortBy at model layer: ${sortBy}`);
        }

        const direction = sortOrder === 'asc' ? 'ASC' : 'DESC';
        const primaryColumn = sortBy === 'name' ? 'p.name' : 'p.altitude';
        const secondaryOrder = sortBy === 'name' ? 'p.altitude DESC' : 'p.name ASC';

        let sql = `
            SELECT DISTINCT
                p.id,
                p.name,
                p.altitude,
                p.latitude,
                p.longitude,
                p.description,
                pp.storage_path AS photo_storage_path
            FROM peaks p
            ${PEAK_PHOTO_JOIN}
            ${join}
            ${where}
            ORDER BY ${primaryColumn} ${direction}, ${secondaryOrder}, p.id ASC
        `;

        // Aquesta paginació limita la quantitat de cims retornats.
        // Ajuda a mantenir el catàleg eficient quan hi ha molts resultats.
        if (Number.isInteger(limit) && limit > 0) {
            sql += ` LIMIT ${limit}`;
            if (offset !== undefined) {
                if (!Number.isInteger(offset) || offset < 0) {
                    throw new Error(`Invalid offset: must be a non-negative integer (received ${offset})`);
                }
                if (offset > 0) {
                    sql += ` OFFSET ${offset}`;
                }
            }
        }

        const [rows] = await pool.execute(sql, [...joinParams, ...whereParams]);
        return attachRegionsToPeaks(rows.map(mapPeakRow));
    },

    // Compta el nombre total de cims que coincideixen amb els filtres.
    // Aquest valor permet al frontend calcular la paginació i mostrar el total de resultats.
    async count({ regionId, minAltitude, maxAltitude, search, status, userId } = {}) {
        const { join, where, joinParams, whereParams } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search, status, userId,
        });

        const sql = `
            SELECT COUNT(DISTINCT p.id) AS total
            FROM peaks p
            ${join}
            ${where}
        `;

        const [rows] = await pool.execute(sql, [...joinParams, ...whereParams]);
        return Number(rows[0].total);
    },

    // Retorna els cims necessaris per representar-los al mapa.
    // Inclou coordenades, imatge i comarques perquè la vista del mapa pugui mostrar la informació bàsica.
    async findAllForMap({ regionId, minAltitude, maxAltitude, search, status, userId } = {}) {
        const { join, where, joinParams, whereParams } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search, status, userId,
        });

        const sql = `
            SELECT DISTINCT
                p.id,
                p.name,
                p.altitude,
                p.latitude,
                p.longitude,
                NULL AS description,
                pp.storage_path AS photo_storage_path
            FROM peaks p
            ${PEAK_PHOTO_JOIN}
            ${join}
            ${where}
            ORDER BY p.altitude DESC, p.name ASC
        `;

        const [rows] = await pool.execute(sql, [...joinParams, ...whereParams]);
        return attachRegionsToPeaks(rows.map(mapPeakRow));
    },

    // Busca un cim pel seu identificador.
    // Retorna també les comarques associades per completar la vista de detall.
    async findById(id) {
        const sqlPeak = `
        SELECT
            p.id,
            p.name,
            p.altitude,
            p.latitude,
            p.longitude,
            p.description,
            pp.storage_path AS photo_storage_path
        FROM peaks p
        ${PEAK_PHOTO_JOIN}
        WHERE p.id = ?
        LIMIT 1
        `;

        const [peakRows] = await pool.execute(sqlPeak, [id]);
        const peak = peakRows[0] ? mapPeakRow(peakRows[0]) : null;

        if (!peak) {
            return null;
        }

        // Aquesta consulta recupera les comarques del cim de manera separada.
        // Això evita duplicar el cim quan pertany a més d’una comarca.
        const sqlRegions = `
        SELECT r.id, r.name
        FROM regions r
        INNER JOIN peak_regions pr ON pr.region_id = r.id
        WHERE pr.peak_id = ?
        ORDER BY r.name ASC
        `;

        const [regionRows] = await pool.execute(sqlRegions, [id]);
        peak.regions = regionRows;

        return peak;
    },
};

module.exports = PeakModel;