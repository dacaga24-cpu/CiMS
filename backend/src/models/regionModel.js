const pool = require('../config/db');


// Accés a la taula regions per alimentar els filtres del catàleg.
const RegionModel = {

    // Totes les comarques ordenades per nom.
    async findAll() {
        const sql = `
        SELECT id, name
        FROM regions
        ORDER BY name ASC
        `;

        const [rows] = await pool.execute(sql);
        return rows;
    },

    // Comarca per id, per validar que existeix abans d'aplicar com a filtre.
    async findById(id) {
        const sql = `
        SELECT id, name
        FROM regions
        WHERE id = ?
        LIMIT 1
        `;

        const [rows] = await pool.execute(sql, [id]);
        return rows[0] || null;
    },
};

module.exports = RegionModel;
