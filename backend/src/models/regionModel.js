const pool = require('../config/db');


// Aquest model centralitza l’accés a les dades de les comarques.
// Permet recuperar-les perquè el catàleg de cims pugui mostrar i aplicar filtres territorials.
const RegionModel = {

    // Retorna totes les comarques disponibles al sistema.
    // Aquesta informació alimenta els filtres del frontend de manera ordenada.
    async findAll() {
        const sql = `
        SELECT id, name
        FROM regions
        ORDER BY name ASC
        `;

        const [rows] = await pool.execute(sql);
        return rows;
    },

    // Busca una comarca a partir del seu identificador.
    // Serveix per comprovar que una regió existeix abans d’utilitzar-la en una consulta.
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