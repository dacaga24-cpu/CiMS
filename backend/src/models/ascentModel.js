const pool = require('../config/db');

// Accés a la taula ascents. A diferència de peak_status, sí que pot tenir
// múltiples registres per a la mateixa parella usuari-cim (un usuari pot
// pujar al mateix cim diverses vegades).
const AscentModel = {

    // Ascensions d'un usuari ordenades per data descendent (les més recents
    // primer). L'ordre secundari per id estabilitza el resultat quan dues
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

    // Ascensions d'un usuari sobre un cim concret, per la pantalla de detall.
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

    // Una ascensió concreta, només si pertany a l'usuari (anti-IDOR). Accepta
    // connection opcional per llegir l'ascens recent dins de la mateixa
    // transacció que l'ha creat.
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

    // Crea una ascensió. Si la FK a peaks falla, es converteix en 404 perquè
    // el servei no hagi de conèixer codis del driver. La connection opcional
    // permet inserir dins d'una transacció (per exemple, per crear ascens i
    // fotos atòmicament).
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

    // Actualitza només els camps presents al payload (modificació parcial).
    // Sense camps a modificar, retorna 0 sense tocar la BD per no renovar
    // updated_at innecessàriament.
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

    // Elimina només si pertany a l'usuari. 0 files afectades = inexistent o
    // d'un altre usuari (el servei respon 404 sense distingir per no filtrar).
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
