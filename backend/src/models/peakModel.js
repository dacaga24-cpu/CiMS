const pool = require('../config/db');


const PeakModel = {


    async findAll({ regionId, minAltitude, maxAltitude, search } = {}) {

        const conditions = [];
        const params = [];

        let sql = `
        SELECT DISTINCT p.id, p.name, p.altitude, p.latitude, p.longitude,
                p.description, p.created_at, p.updated_at
        FROM peaks p
        `;

        if (regionId) {
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