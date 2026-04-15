const pool = require('../config/db');


// Aquest model centralitza l'accés a les dades de les comarques.
// La seva funció és recuperar les regions disponibles al sistema
// perquè es puguin fer servir als filtres del catàleg de cims.
const RegionModel = {

    // Aquest mètode retorna totes les comarques del sistema.
    // És rellevant perquè alimenta els desplegables i filtres del front
    // on l'usuari pot escollir una regió concreta.
    async findAll() {
        const sql = `
        SELECT id, name, created_at, updated_at
        FROM regions
        ORDER BY name ASC
        `;

        const [rows] = await pool.execute(sql);
        return rows;
    },

    // Aquest mètode busca una comarca pel seu identificador.
    // Es fa servir per validar que una regió existeix abans d'aplicar-la
    // com a filtre en les consultes de cims.
    async findById(id) {
        const sql = `
        SELECT id, name, created_at, updated_at
        FROM regions
        WHERE id = ?
        LIMIT 1
        `;

        const [rows] = await pool.execute(sql, [id]);
        return rows[0] || null;
    },
};

module.exports = RegionModel;