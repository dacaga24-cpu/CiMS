const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades de l'estat personal que
// cada usuari manté sobre els cims (completat, objectiu, preferit).
// La seva funció és exposar les operacions bàsiques sobre la taula
// peak_status perquè els serveis puguin llegir i actualitzar aquests
// estats sense escampar SQL per la resta del codi.
const PeakStatusModel = {

    // Aquest mètode retorna l'estat d'un cim concret per a un usuari concret.
    // Es fa servir per consultar els flags individuals i també per detectar
    // si ja existeix un registre abans de decidir si s'ha de crear o actualitzar.
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

    // Aquest mètode retorna tots els estats que un usuari té marcats.
    // És rellevant per alimentar pantalles com "els meus cims completats",
    // "objectius" o "preferits" sense haver de fer una consulta per cim.
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

    // Aquest mètode crea un nou registre d'estat per a la parella usuari-cim.
    // La unicitat està garantida a l'schema amb uq_peak_status_user_peak
    // (user_id, peak_id), de manera que mai poden coexistir dos registres
    // per al mateix usuari i cim. Si el driver llença ER_DUP_ENTRY perquè
    // ja existeix la parella, es converteix en un error de domini amb
    // statusCode 409 perquè la capa de servei no hagi de conèixer codis
    // concrets del driver i pugui respondre amb un conflicte clar.
    async create({ userId, peakId, isCompleted = 0, isTarget = 0, isFavorite = 0 }) {
        const sql = `
        INSERT INTO peak_status (user_id, peak_id, is_completed, is_target, is_favorite)
        VALUES (?, ?, ?, ?, ?)
        `;

        try {
            const [result] = await pool.execute(sql, [
                userId,
                peakId,
                isCompleted ? 1 : 0,
                isTarget ? 1 : 0,
                isFavorite ? 1 : 0,
            ]);

            return {
                id: result.insertId,
                user_id: userId,
                peak_id: peakId,
                is_completed: isCompleted ? 1 : 0,
                is_target: isTarget ? 1 : 0,
                is_favorite: isFavorite ? 1 : 0,
            };
        } catch (err) {
            if (err && err.code === 'ER_DUP_ENTRY') {
                const error = new Error('Peak status already exists for this user and peak');
                error.statusCode = 409;
                throw error;
            }
            throw err;
        }
    },

    // Aquest mètode actualitza els flags d'un registre ja existent per a la
    // parella usuari-cim. Només s'escriuen els camps que s'han indicat
    // explícitament a l'objecte rebut, cosa que permet canviar un sol flag
    // sense haver de reescriure els altres des del servei.
    async updateByUserAndPeak(userId, peakId, { isCompleted, isTarget, isFavorite } = {}) {
        const fields = [];
        const params = [];

        if (isCompleted !== undefined) {
            fields.push('is_completed = ?');
            params.push(isCompleted ? 1 : 0);
        }

        if (isTarget !== undefined) {
            fields.push('is_target = ?');
            params.push(isTarget ? 1 : 0);
        }

        if (isFavorite !== undefined) {
            fields.push('is_favorite = ?');
            params.push(isFavorite ? 1 : 0);
        }

        // Si no hi ha cap flag a modificar es retorna 0 sense tocar la base de
        // dades per evitar consultes innecessàries amb updated_at renovat.
        if (fields.length === 0) {
            return 0;
        }

        const sql = `
        UPDATE peak_status
        SET ${fields.join(', ')}
        WHERE user_id = ? AND peak_id = ?
        `;

        params.push(userId, peakId);

        const [result] = await pool.execute(sql, params);
        return result.affectedRows;
    },

    // Aquest mètode elimina el registre d'estat d'un cim per a un usuari.
    // S'utilitza quan cal netejar completament els flags (per exemple si
    // l'usuari decideix treure's un cim de la llista) en comptes de
    // mantenir una fila amb tots els flags a zero.
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
