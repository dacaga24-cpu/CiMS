const pool = require('../config/db');

// Accés a dades dels cims: catàleg amb filtres i unió amb les comarques.

// Construeix el WHERE i els paràmetres dels filtres del catàleg. S'extreu
// per garantir que les tres consultes (paginada, mapa, comptador) apliquin
// exactament el mateix conjunt de filtres.
function buildPeakFilters({ regionId, minAltitude, maxAltitude, search } = {}) {
    const conditions = [];
    const params = [];
    let join = '';

    if (regionId !== undefined && regionId !== null) {
        join = ' INNER JOIN peak_regions pr ON pr.peak_id = p.id ';
        conditions.push('pr.region_id = ?');
        params.push(regionId);
    }

    if (minAltitude !== undefined && minAltitude !== null) {
        conditions.push('p.altitude >= ?');
        params.push(minAltitude);
    }

    if (maxAltitude !== undefined && maxAltitude !== null) {
        conditions.push('p.altitude <= ?');
        params.push(maxAltitude);
    }

    if (search) {
        conditions.push('p.name LIKE ?');
        params.push(`%${search}%`);
    }

    const where = conditions.length > 0 ? ' WHERE ' + conditions.join(' AND ') : '';
    return { join, where, params };
}

// Adjunta les comarques a una llista de cims amb una sola query agrupada
// per peak_id, evitant el patró N+1.
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

    // Llista paginada de cims que compleixen els filtres. L'ordre per altitud
    // descendent + nom ascendent és estable i imprescindible: sense ORDER BY
    // determinístic, dues pàgines podrien repetir o saltar-se cims.
    async findAll({ regionId, minAltitude, maxAltitude, search, limit, offset } = {}) {
        const { join, where, params } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search,
        });

        let sql = `
            SELECT DISTINCT p.id, p.name, p.altitude, p.latitude, p.longitude, p.description
            FROM peaks p
            ${join}
            ${where}
            ORDER BY p.altitude DESC, p.name ASC
        `;

        // LIMIT i OFFSET s'interpolen perquè pool.execute() (statements
        // preparats) els tracta com a strings i MySQL els rebutja. Es
        // valida explícitament Number.isInteger abans d'incloure'ls al
        // SQL: defensa local contra qualsevol tipus inesperat.
        //
        // Sense LIMIT no s'aplica OFFSET (SQL standard ho exigeix); això
        // força la convenció que la paginació sempre porta mida de pàgina.
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

        const [rows] = await pool.execute(sql, params);
        return attachRegionsToPeaks(rows);
    },

    // Compta cims que coincideixen amb els filtres per omplir totalItems
    // de la resposta paginada. COUNT(DISTINCT p.id) perquè el JOIN amb
    // peak_regions duplica files quan un cim té diverses comarques.
    async count({ regionId, minAltitude, maxAltitude, search } = {}) {
        const { join, where, params } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search,
        });

        const sql = `
            SELECT COUNT(DISTINCT p.id) AS total
            FROM peaks p
            ${join}
            ${where}
        `;

        const [rows] = await pool.execute(sql, params);
        return Number(rows[0].total);
    },

    // Cims per a la vista de mapa amb només els camps mínims (id, nom,
    // coordenades, altitud). Sense límit perquè el mapa ha de mostrar el
    // conjunt complet que casi amb els filtres.
    async findAllForMap({ regionId, minAltitude, maxAltitude, search } = {}) {
        const { join, where, params } = buildPeakFilters({
            regionId, minAltitude, maxAltitude, search,
        });

        const sql = `
            SELECT DISTINCT p.id, p.name, p.altitude, p.latitude, p.longitude
            FROM peaks p
            ${join}
            ${where}
            ORDER BY p.altitude DESC, p.name ASC
        `;

        const [rows] = await pool.execute(sql, params);
        return rows;
    },

    // Cim per id amb les seves comarques. Les comarques en una segona query
    // (no JOIN a la principal) per no duplicar files quan un cim té diverses.
    async findById(id) {
        const sqlPeak = `
        SELECT id, name, altitude, latitude, longitude, description
        FROM peaks
        WHERE id = ?
        LIMIT 1
        `;

        const [peakRows] = await pool.execute(sqlPeak, [id]);
        const peak = peakRows[0];

        if (!peak) {
            return null;
        }

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
