const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades de les ascensions registrades
// pels usuaris. Cada ascensió representa una pujada concreta d'un usuari a un
// cim, amb data opcional, notes i possibles fotos associades.
//
// A diferència de peak_status, aquí sí que poden existir múltiples registres
// per a la mateixa parella usuari-cim. Això permet que un usuari pugui pujar
// diverses vegades al mateix cim i conservar cada registre de manera separada.
//
// Tots els SELECT inclouen explícitament les columnes per garantir un format
// estable de resposta i mantenir el snake_case de la base de dades, que és
// el format que el frontend ja consumeix.
const AscentModel = {

    // Aquest mètode retorna totes les ascensions d'un usuari ordenades per
    // data descendent. Les ascensions sense data queden igualment disponibles
    // per al sistema, però la interfície podrà decidir si les mostra o només
    // les utilitza per marcar el cim com a completat.
    async findAllByUserId(userId) {
        const sql = `
        SELECT id, user_id, peak_id, ascent_date, notes, created_at, updated_at
        FROM ascents
        WHERE user_id = ?
        ORDER BY ascent_date DESC, id DESC
        `;

        const [rows] = await pool.execute(sql, [userId]);
        return rows;
    },

    // Aquest mètode retorna les ascensions d'un usuari sobre un cim concret.
    // S'utilitza a la pantalla de detall del cim per consultar els registres
    // personals associats a aquell cim i mantenir la coherència amb el seu estat.
    async findAllByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT id, user_id, peak_id, ascent_date, notes, created_at, updated_at
        FROM ascents
        WHERE user_id = ? AND peak_id = ?
        ORDER BY ascent_date DESC, id DESC
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return rows;
    },

    // Aquest mètode retorna una ascensió concreta, però només si pertany a
    // l'usuari indicat. Aquesta restricció evita que un usuari pugui llegir
    // o modificar ascensions d'un altre encara que conegui l'identificador
    // del registre.
    //
    // Accepta una connexió opcional per poder llegir una ascensió acabada de
    // crear dins de la mateixa transacció.
    async findByIdAndUserId(userId, ascentId, connection) {
        const executor = connection || pool;
        const sql = `
        SELECT id, user_id, peak_id, ascent_date, notes, created_at, updated_at
        FROM ascents
        WHERE id = ? AND user_id = ?
        LIMIT 1
        `;

        const [rows] = await executor.execute(sql, [ascentId, userId]);
        return rows[0] || null;
    },

    // Aquest mètode crea una nova ascensió. La data pot ser nul·la quan
    // l'usuari vol registrar que ha completat un cim però no recorda quan
    // va fer l'ascensió.
    //
    // Si el peak_id referenciat no existeix, MySQL llança un error de foreign
    // key i aquí es transforma en un 404 amb un missatge funcional.
    //
    // Accepta opcionalment una connexió del pool perquè el servei pugui crear
    // l'ascensió i les seves fotos dins d'una mateixa transacció.
    async create({ userId, peakId, ascentDate = null, notes = null }, connection) {
        const executor = connection || pool;
        const sql = `
        INSERT INTO ascents (user_id, peak_id, ascent_date, notes)
        VALUES (?, ?, ?, ?)
        `;

        try {
            const [result] = await executor.execute(sql, [
                userId,
                peakId,
                ascentDate,
                notes,
            ]);

            return this.findByIdAndUserId(userId, result.insertId, connection);
        } catch (err) {
            if (err && (err.code === 'ER_NO_REFERENCED_ROW' || err.code === 'ER_NO_REFERENCED_ROW_2')) {
                const error = new Error('Peak not found');
                error.statusCode = 404;
                throw error;
            }
            throw err;
        }
    },

    // Aquest mètode actualitza els camps indicats d'una ascensió ja existent.
    // Només s'escriuen els camps presents al payload, de manera que el client
    // pot modificar només la data, només les notes o el cim associat sense
    // reenviar tota la informació.
    //
    // També permet deixar la data com a null, mantenint el cas d'ús en què
    // l'usuari registra un cim completat però no recorda la data exacta.
    async updateByIdAndUserId(userId, ascentId, { peakId, ascentDate, notes } = {}) {
        const fields = [];
        const params = [];

        if (peakId !== undefined) {
            fields.push('peak_id = ?');
            params.push(peakId);
        }

        if (ascentDate !== undefined) {
            fields.push('ascent_date = ?');
            params.push(ascentDate);
        }

        if (notes !== undefined) {
            fields.push('notes = ?');
            params.push(notes);
        }

        if (fields.length === 0) {
            return 0;
        }

        const sql = `
        UPDATE ascents
        SET ${fields.join(', ')}
        WHERE id = ? AND user_id = ?
        `;

        params.push(ascentId, userId);

        try {
            const [result] = await pool.execute(sql, params);
            return result.affectedRows;
        } catch (err) {
            if (err && (err.code === 'ER_NO_REFERENCED_ROW' || err.code === 'ER_NO_REFERENCED_ROW_2')) {
                const error = new Error('Peak not found');
                error.statusCode = 404;
                throw error;
            }
            throw err;
        }
    },

    // Aquest mètode compta quantes ascensions conserva un usuari sobre un cim.
    // Serveix per saber si el cim ha de continuar marcat com a completat després
    // d'eliminar o modificar una ascensió.
    async countByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT COUNT(*) AS total
        FROM ascents
        WHERE user_id = ? AND peak_id = ?
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return Number(rows[0].total);
    },

    // Aquest mètode elimina una ascensió només si pertany a l'usuari indicat.
    // Si no s'ha eliminat cap fila, el servei pot interpretar-ho com a ascensió
    // inexistent o d'un altre usuari i respondre 404 sense exposar informació.
    async deleteByIdAndUserId(userId, ascentId) {
        const sql = `
        DELETE FROM ascents
        WHERE id = ? AND user_id = ?
        `;

        const [result] = await pool.execute(sql, [ascentId, userId]);
        return result.affectedRows;
    },
};

module.exports = AscentModel;