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
        // Es parteix d'una base amb LEFT JOIN a peak_regions i regions
        // per poder agrupar les comarques de cada cim en un sol camp.
        // D'aquesta manera s'evita haver de fer una consulta per cada cim
        // a l'hora de mostrar el catàleg.
        const conditions = [];
        const params = [];

        let sql = `
        SELECT p.id, p.name, p.altitude, p.latitude, p.longitude, p.description,
               GROUP_CONCAT(r.name ORDER BY r.name ASC SEPARATOR ', ') AS regions
        FROM peaks p
        LEFT JOIN peak_regions pr ON pr.peak_id = p.id
        LEFT JOIN regions r ON r.id = pr.region_id
        `;

        // El filtre per regió es resol reutilitzant el mateix JOIN ja definit,
        // així no cal afegir una taula addicional només per filtrar.
        if (regionId !== undefined && regionId !== null) {
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

        // L'agrupació per p.id és necessària perquè cada cim torni en una sola fila
        // tot i tenir múltiples comarques associades.
        sql += ' GROUP BY p.id ORDER BY p.name ASC';

        const [rows] = await pool.execute(sql, params);
        return rows;
    },

    // Aquest mètode busca un cim pel seu identificador i hi afegeix
    // la llista de comarques a les quals pertany.
    // Es fa servir a la pantalla de detall del cim.
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
