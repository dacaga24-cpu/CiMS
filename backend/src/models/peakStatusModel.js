const pool = require('../config/db');

// Coerciona "truthy/falsy" a 1/0 que MySQL utilitza per a booleans. Centralitzat
// per garantir un tractament uniforme de la coerció.
function coerceBool(value) {
  return value ? 1 : 0;
}

// Accés a peak_status: l'estat personal (completat/objectiu/preferit) que cada
// usuari manté sobre cada cim.
const PeakStatusModel = {

    // Estat d'un cim concret per a un usuari concret.
    async findByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT id, user_id, peak_id, is_completed, is_target, is_favorite
        FROM peak_status
        WHERE user_id = ? AND peak_id = ?
        LIMIT 1
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return rows[0] || null;
    },

    // Tots els estats d'un usuari, ordenats per modificació més recent.
    async findAllByUserId(userId) {
        const sql = `
        SELECT id, user_id, peak_id, is_completed, is_target, is_favorite
        FROM peak_status
        WHERE user_id = ?
        ORDER BY updated_at DESC
        `;

        const [rows] = await pool.execute(sql, [userId]);
        return rows;
    },

    // Crea un registre per a la parella usuari-cim. ER_DUP_ENTRY (UNIQUE
    // user_id, peak_id) es converteix en 409 i ER_NO_REFERENCED_ROW (FK a
    // peaks) en 404, perquè la capa de servei no hagi de conèixer codis
    // del driver.
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

    // Actualitza només els flags presents al payload, així es pot canviar un
    // sol flag sense reescriure els altres.
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

        // Sense flags a modificar, no toquem la BD per no renovar updated_at.
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
            // Coherent amb create: FK trencada cap a peaks → 404.
            if (err && (err.code === 'ER_NO_REFERENCED_ROW' || err.code === 'ER_NO_REFERENCED_ROW_2')) {
                const error = new Error('Peak not found');
                error.statusCode = 404;
                throw error;
            }
            throw err;
        }
    },

    // Elimina el registre d'estat. S'usa quan tots els flags queden a zero
    // per no mantenir files buides a la taula.
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
