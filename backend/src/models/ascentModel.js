const pool = require('../config/db');

// Aquest model centralitza l’accés a les dades de les ascensions.
// Permet consultar, crear, actualitzar i eliminar registres mantenint la propietat de cada usuari.
const AscentModel = {

    // Retorna totes les ascensions d’un usuari.
    // Inclou la informació de verificació per diferenciar ascensions manuals i verificades.
    async findAllByUserId(userId) {
        const sql = `
        SELECT
            a.id,
            a.user_id,
            a.peak_id,
            a.ascent_date,
            a.notes,
            a.is_date_locked,
            a.created_at,
            a.updated_at,
            av.id AS verification_id,
            av.method AS verification_method,
            av.status AS verification_status,
            av.distance_to_peak_meters AS verification_distance_to_peak_meters,
            av.checked_at AS verification_checked_at,
            av.reason AS verification_reason
        FROM ascents a
        LEFT JOIN ascent_verifications av ON av.ascent_id = a.id
        WHERE a.user_id = ?
        ORDER BY a.ascent_date DESC, a.id DESC
        `;

        const [rows] = await pool.execute(sql, [userId]);
        return rows;
    },

    // Retorna les ascensions d’un usuari associades a un cim concret.
    // Aquesta consulta permet mostrar l’historial personal dins del detall del cim.
    async findAllByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT
            a.id,
            a.user_id,
            a.peak_id,
            a.ascent_date,
            a.notes,
            a.is_date_locked,
            a.created_at,
            a.updated_at,
            av.id AS verification_id,
            av.method AS verification_method,
            av.status AS verification_status,
            av.distance_to_peak_meters AS verification_distance_to_peak_meters,
            av.checked_at AS verification_checked_at,
            av.reason AS verification_reason
        FROM ascents a
        LEFT JOIN ascent_verifications av ON av.ascent_id = a.id
        WHERE a.user_id = ? AND a.peak_id = ?
        ORDER BY a.ascent_date DESC, a.id DESC
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return rows;
    },

    // Retorna una ascensió concreta només si pertany a l’usuari indicat.
    // La connexió opcional permet reutilitzar aquest mètode dins d’una transacció.
    async findByIdAndUserId(userId, ascentId, connection) {
        const executor = connection || pool;
        const sql = `
        SELECT
            a.id,
            a.user_id,
            a.peak_id,
            a.ascent_date,
            a.notes,
            a.is_date_locked,
            a.created_at,
            a.updated_at,
            av.id AS verification_id,
            av.method AS verification_method,
            av.status AS verification_status,
            av.distance_to_peak_meters AS verification_distance_to_peak_meters,
            av.checked_at AS verification_checked_at,
            av.reason AS verification_reason
        FROM ascents a
        LEFT JOIN ascent_verifications av ON av.ascent_id = a.id
        WHERE a.id = ? AND a.user_id = ?
        LIMIT 1
        `;

        const [rows] = await executor.execute(sql, [ascentId, userId]);
        return rows[0] || null;
    },

    // Crea una nova ascensió per a un usuari i un cim.
    // El bloqueig de data s’utilitza quan l’ascensió prové d’un procés de verificació.
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

    // Actualitza els camps indicats d’una ascensió existent.
    // La data no es modifica si l’ascensió està bloquejada per una verificació.
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

    // Compta les ascensions d’un usuari sobre un cim concret.
    // Aquest resultat ajuda a decidir si el cim ha de continuar marcat com a completat.
    async countByUserAndPeak(userId, peakId) {
        const sql = `
        SELECT COUNT(*) AS total
        FROM ascents
        WHERE user_id = ? AND peak_id = ?
        `;

        const [rows] = await pool.execute(sql, [userId, peakId]);
        return Number(rows[0].total);
    },

    // Elimina una ascensió només si pertany a l’usuari indicat.
    // Retorna el nombre de registres eliminats perquè el servei pugui interpretar el resultat.
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