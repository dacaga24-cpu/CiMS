const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades de les ascensions registrades pels usuaris.
// Cada ascensió representa una pujada concreta d'un usuari a un cim, amb data opcional,
// notes, bloqueig de data i possibles fotos associades.
const AscentModel = {

    // Aquest mètode retorna totes les ascensions d'un usuari.
    // S'utilitza per construir l'historial personal i mantenir el seguiment de l'activitat.
    async findAllByUserId(userId) {
        const sql = `
        SELECT id, user_id, peak_id, ascent_date, notes, is_date_locked, created_at, updated_at
        FROM ascents
        WHERE user_id = ?
        ORDER BY ascent_date DESC, id DESC
        `;

        const [rows] = await pool.execute(sql, [userId]);
        return rows;
    },

    // Aquest mètode retorna les ascensions d'un usuari sobre un cim concret.
    // Permet mostrar l'historial personal associat al detall d'un cim.
    async findAllByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT id, user_id, peak_id, ascent_date, notes, is_date_locked, created_at, updated_at
        FROM ascents
        WHERE user_id = ? AND peak_id = ?
        ORDER BY ascent_date DESC, id DESC
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return rows;
    },

    // Aquest mètode retorna una ascensió concreta només si pertany a l'usuari indicat.
    // També accepta una connexió opcional per poder treballar dins d'una transacció.
    async findByIdAndUserId(userId, ascentId, connection) {
        const executor = connection || pool;
        const sql = `
        SELECT id, user_id, peak_id, ascent_date, notes, is_date_locked, created_at, updated_at
        FROM ascents
        WHERE id = ? AND user_id = ?
        LIMIT 1
        `;

        const [rows] = await executor.execute(sql, [ascentId, userId]);
        return rows[0] || null;
    },

    // Aquest mètode crea una nova ascensió.
    // El camp isDateLocked permet bloquejar la data quan l'ascensió prové d'una verificació.
    async create(
        { userId, peakId, ascentDate = null, notes = null, isDateLocked = 0 },
        connection
    ) {
        const executor = connection || pool;
        const sql = `
        INSERT INTO ascents (user_id, peak_id, ascent_date, notes, is_date_locked)
        VALUES (?, ?, ?, ?, ?)
        `;

        try {
            const [result] = await executor.execute(sql, [
                userId,
                peakId,
                ascentDate,
                notes,
                isDateLocked,
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

    // Aquest mètode actualitza els camps indicats d'una ascensió existent.
    // No modifica la data si l'ascensió està bloquejada per haver estat verificada.
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
          AND (is_date_locked = 0 OR ? IS NULL)
        `;

        params.push(ascentId, userId, ascentDate === undefined ? null : ascentDate);

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
    // Serveix per decidir si el cim ha de continuar marcat com a completat.
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
    // Si no s'elimina cap fila, el servei podrà respondre com a registre inexistent.
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