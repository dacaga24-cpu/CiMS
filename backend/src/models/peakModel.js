const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades dels cims.
// La seva funció és recuperar cims, aplicar filtres del catàleg
// i unir-los amb les comarques a les quals pertanyen.
const PeakModel = {

    // Aquest mètode retorna la llista de cims que compleixen els filtres rebuts.
    // Tots els filtres són opcionals i es combinen amb AND,
    // de manera que si no s'especifica cap filtre es retornen tots els cims.
    // El paràmetre limit és un sostre defensiu definit pel servei per evitar
    // que una cerca massa permissiva retorni un volum desmesurat de resultats.
    async findAll({ regionId, minAltitude, maxAltitude, search, limit } = {}) {

        // La consulta dels cims i la de les comarques es fan per separat
        // per poder retornar les comarques com una llista d'objectes {id, name},
        // mantenint exactament el mateix format que findById i evitant que
        // el frontend hagi de tractar dos tipus de resposta diferents.
        const peakConditions = [];
        const peakParams = [];
        let peakJoin = '';

        // El filtre per regió obliga a restringir els cims a aquells que
        // tenen alguna entrada a peak_regions per la comarca demanada.
        // S'aplica aquí perquè filtri la llista de cims, no les comarques
        // retornades per cada cim.
        if (regionId !== undefined && regionId !== null) {
            peakJoin = ' INNER JOIN peak_regions pr ON pr.peak_id = p.id ';
            peakConditions.push('pr.region_id = ?');
            peakParams.push(regionId);
        }

        if (minAltitude !== undefined && minAltitude !== null) {
            peakConditions.push('p.altitude >= ?');
            peakParams.push(minAltitude);
        }

        if (maxAltitude !== undefined && maxAltitude !== null) {
            peakConditions.push('p.altitude <= ?');
            peakParams.push(maxAltitude);
        }

        // La cerca per nom és insensible a majúscules gràcies al collation utf8mb4_unicode_ci
        // definit a l'schema, de manera que no cal forçar LOWER() a la consulta.
        if (search) {
            peakConditions.push('p.name LIKE ?');
            peakParams.push(`%${search}%`);
        }

        let peakSql = `
            SELECT DISTINCT p.id, p.name, p.altitude, p.latitude, p.longitude, p.description
            FROM peaks p
            ${peakJoin}
        `;

        if (peakConditions.length > 0) {
            peakSql += ' WHERE ' + peakConditions.join(' AND ');
        }

        // Es fa un ORDER BY per garantir que els cims es mostren sempre en el mateix ordre,
        // primer per altitud descendent i després per nom ascendent per facilitar la lectura.
        peakSql += ' ORDER BY p.altitude DESC, p.name ASC';

        // El LIMIT s'interpola directament a la consulta perquè mysql2 no suporta
        // paràmetres preparats per a LIMIT en totes les versions, però el valor
        // és un enter validat al servei i mai prové de l'usuari directament.
        if (Number.isInteger(limit) && limit > 0) {
            peakSql += ` LIMIT ${limit}`;
        }

        const [peakRows] = await pool.execute(peakSql, peakParams);

        if (peakRows.length === 0) {
            return [];
        }

        // Amb els cims ja filtrats, es recuperen totes les comarques associades
        // en una sola consulta agrupada per peak_id. Això evita fer una consulta
        // per cada cim (N+1) i manté l'eficiència del catàleg.
        const peakIds = peakRows.map((peak) => peak.id);
        const placeholders = peakIds.map(() => '?').join(', ');
        const regionsSql = `
            SELECT pr.peak_id, r.id, r.name
            FROM peak_regions pr
            INNER JOIN regions r ON r.id = pr.region_id
            WHERE pr.peak_id IN (${placeholders})
            ORDER BY r.name ASC
        `;

        const [regionRows] = await pool.execute(regionsSql, peakIds);

        // Es construeix un mapa de peak_id a llista de comarques per poder
        // assignar de manera eficient les comarques a cada cim.
        const regionsByPeakId = new Map();
        for (const row of regionRows) {
            if (!regionsByPeakId.has(row.peak_id)) {
                regionsByPeakId.set(row.peak_id, []);
            }
            regionsByPeakId.get(row.peak_id).push({ id: row.id, name: row.name });
        }

        for (const peak of peakRows) {
            peak.regions = regionsByPeakId.get(peak.id) || [];
        }

        return peakRows;
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
