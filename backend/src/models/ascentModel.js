const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades de les ascensions registrades
// pels usuaris. Cada ascensió representa una pujada concreta d'un usuari a un
// cim en una data determinada, i a diferència de peak_status, sí que pot tenir
// múltiples registres per a la mateixa parella usuari-cim (un usuari pot
// pujar al mateix cim diverses vegades).
//
// Tots els SELECT inclouen explícitament les columnes per garantir un format
// estable de resposta i mantenir el snake_case de la base de dades, que és
// el format que el frontend ja consumeix.
const AscentModel = {

    // Aquest mètode retorna totes les ascensions d'un usuari ordenades per
    // data descendent, perquè a la interfície tingui sentit veure primer les
    // més recents. L'ordre secundari per id estabilitza el resultat quan dues
    // ascensions tenen la mateixa data.
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
    // S'utilitza a la pantalla de detall del cim per mostrar l'historial
    // personal de pujades de l'usuari autenticat.
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
    // (protecció contra IDOR). Accepta connection opcional per quan cal
    // llegir l'ascens acabat de crear dins de la mateixa transacció.
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

    // Aquest mètode crea una nova ascensió. Si el peak_id referenciat no
    // existeix, MySQL llança ER_NO_REFERENCED_ROW_2 per la foreign key i
    // aquí el convertim en un error 404 amb un missatge clar perquè la capa
    // de servei no hagi de conèixer codis específics del driver.
    //
    // Accepta opcionalment una `connection` del pool perquè el caller pugui
    // executar la inserció dins d'una transacció (per exemple, per crear
    // l'ascens i les seves fotos atòmicament). Si no es passa, es fa servir
    // el pool directament i la inserció és independent.
    async create({ userId, peakId, ascentDate, notes = null }, connection) {
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
    // Només s'escriuen els camps presents al payload, de manera que un client
    // pot modificar només la data o només les notes sense haver de reenviar
    // la resta. Si no hi ha res a modificar es retorna 0 sense tocar la base
    // de dades, evitant un UPDATE inútil que renovaria el updated_at.
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

    // Aquest mètode elimina una ascensió només si pertany a l'usuari indicat.
    // Si no s'ha eliminat cap fila, el servei pot interpretar-ho com a
    // ascensió inexistent o d'un altre usuari (en tots dos casos respon 404,
    // per no filtrar quines ascensions existeixen al sistema).
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
