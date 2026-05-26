const pool = require('../config/db');

// Aquest mètode adapta valors booleans al format utilitzat per MySQL.
// Centralitza la conversió perquè els estats es guardin sempre de manera coherent.
function coerceBool(value) {
  return value ? 1 : 0;
}

// Aquest model gestiona l’estat personal dels cims per usuari.
// Permet consultar, crear, actualitzar i eliminar les marques associades a cada cim.
const PeakStatusModel = {

    // Retorna l’estat d’un cim concret per a un usuari.
    // Inclou si existeix una ascensió verificada per mostrar aquesta informació al frontend.
    async findByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT
            ps.id,
            ps.user_id,
            ps.peak_id,
            ps.is_completed,
            ps.is_target,
            ps.is_favorite,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM ascents a
                    INNER JOIN ascent_verifications av ON av.ascent_id = a.id
                    WHERE a.user_id = ps.user_id
                      AND a.peak_id = ps.peak_id
                      AND av.status = 'verified'
                )
                THEN 1
                ELSE 0
            END AS has_verified_ascent
        FROM peak_status ps
        WHERE ps.user_id = ? AND ps.peak_id = ?
        LIMIT 1
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return rows[0] || null;
    },

    // Retorna tots els estats personals d’un usuari.
    // Aquesta informació permet sincronitzar les marques de progrés al catàleg, el mapa i el detall del cim.
    async findAllByUserId(userId) {
        const sql = `
        SELECT
            ps.id,
            ps.user_id,
            ps.peak_id,
            ps.is_completed,
            ps.is_target,
            ps.is_favorite,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM ascents a
                    INNER JOIN ascent_verifications av ON av.ascent_id = a.id
                    WHERE a.user_id = ps.user_id
                      AND a.peak_id = ps.peak_id
                      AND av.status = 'verified'
                )
                THEN 1
                ELSE 0
            END AS has_verified_ascent
        FROM peak_status ps
        WHERE ps.user_id = ?
        ORDER BY ps.updated_at DESC
        `;

        const [rows] = await pool.execute(sql, [userId]);
        return rows;
    },

    // Crea un nou estat personal per a un cim.
    // S’utilitza quan l’usuari marca per primera vegada un cim dins del seu seguiment.
    async create({ userId, peakId, isCompleted = 0, isTarget = 0, isFavorite = 0 }) {
        const sql = `
        INSERT INTO peak_status (user_id, peak_id, is_completed, is_target, is_favorite)
        VALUES (?, ?, ?, ?, ?)
        `;

        try {
            const [result] = await pool.execute(sql, [
                userId,
                peakId,
                coerceBool(isCompleted),
                coerceBool(isTarget),
                coerceBool(isFavorite),
            ]);

            return {
                id: result.insertId,
                user_id: userId,
                peak_id: peakId,
                is_completed: coerceBool(isCompleted),
                is_target: coerceBool(isTarget),
                is_favorite: coerceBool(isFavorite),
                has_verified_ascent: 0,
            };
        } catch (err) {
            if (err && err.code === 'ER_DUP_ENTRY') {
                const error = new Error('Peak status already exists for this user and peak');
                error.statusCode = 409;
                throw error;
            }

            if (err && (err.code === 'ER_NO_REFERENCED_ROW' || err.code === 'ER_NO_REFERENCED_ROW_2')) {
                const error = new Error('Peak not found');
                error.statusCode = 404;
                throw error;
            }

            throw err;
        }
    },

    // Actualitza les marques personals d’un cim.
    // Només modifica els camps rebuts per conservar la resta de l’estat sense canvis.
    async updateByUserAndPeak(userId, peakId, { isCompleted, isTarget, isFavorite } = {}) {
        const fields = [];
        const params = [];

        if (isCompleted !== undefined) {
            fields.push('is_completed = ?');
            params.push(coerceBool(isCompleted));
        }

        if (isTarget !== undefined) {
            fields.push('is_target = ?');
            params.push(coerceBool(isTarget));
        }

        if (isFavorite !== undefined) {
            fields.push('is_favorite = ?');
            params.push(coerceBool(isFavorite));
        }

        if (fields.length === 0) {
            return 0;
        }

        const sql = `
        UPDATE peak_status
        SET ${fields.join(', ')}
        WHERE user_id = ? AND peak_id = ?
        `;

        params.push(userId, peakId);

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

    // Elimina l’estat personal d’un cim.
    // Aquesta acció s’utilitza quan ja no queda cap marca activa per a aquell usuari i cim.
    async deleteByUserAndPeak(userId, peakId) {
        const sql = `
        DELETE FROM peak_status
        WHERE user_id = ? AND peak_id = ?
        `;

        const [result] = await pool.execute(sql, [userId, peakId]);
        return result.affectedRows;
    },
};

module.exports = PeakStatusModel;