const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades dels cims.
// La seva funció és recuperar cims, aplicar filtres del catàleg
// i unir-los amb les comarques a les quals pertanyen.
const PeakModel = {

    // Aquest mètode retorna la llista de cims que compleixen els filtres rebuts.
    // Tots els filtres són opcionals i es combinen amb AND,
    // de manera que si no s'especifica cap filtre es retornen tots els cims.
    async findAll({ regionId, minAltitude, maxAltitude, search } = {}) {

        // Aquest bloc construeix la consulta de forma dinàmica.
        // Es parteix d'una base amb JOIN a peak_regions només quan cal filtrar per regió,
        // per evitar duplicar files quan un cim pertany a més d'una comarca.
        const conditions = [];
        const params = [];

        let sql = `
        SELECT DISTINCT p.id, p.name, p.altitude, p.latitude, p.longitude,
                p.description
        FROM peaks p
        `;

        if (regionId !== undefined && regionId !== null) {
        sql += ` INNER JOIN peak_regions pr ON pr.peak_id = p.id `;
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

        // La cerca per nom és insensible a majúscules gràcies al collation utf8mb4_unicode_ci
        // definit a l'schema, de manera que no cal forçar LOWER() a la consulta.
        if (search) {
        conditions.push('p.name LIKE ?');
        params.push(`%${search}%`);
        }

        if (conditions.length > 0) {
        sql += ' WHERE ' + conditions.join(' AND ');
        }

        sql += ' ORDER BY p.name ASC';

        const [rows] = await pool.execute(sql, params);
        return rows;
    },

    // Aquest mètode busca un cim pel seu identificador i hi afegeix
    // la llista de comarques a les quals pertany.
    // Es fa servir a la pantalla de detall del cim.
    async findById(id) {
        const sqlPeak = `
        SELECT id, name, altitude, latitude, longitude, description,
                created_at, updated_at
        FROM peaks
        WHERE id = ?
        LIMIT 1
        `;

        const [peakRows] = await pool.execute(sqlPeak, [id]);
        const peak = peakRows[0];

        if (!peak) {
        return null;
        }

        // Aquesta segona consulta recupera les comarques associades al cim.
        // Es fa en una crida separada per mantenir la resposta ben estructurada
        // i evitar files duplicades a la consulta principal.
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