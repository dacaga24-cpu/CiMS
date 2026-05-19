const pool = require('../config/db');

// Aquest model gestiona l’accés a les dades de verificació d’una ascensió.
// Separa la prova de validació de l’activitat principal registrada a ascents.
const AscentVerificationModel = {
    // Aquest mètode crea la verificació associada a una ascensió.
    // Rep el resultat calculat pel servei de verificació i el desa a la base de dades.
    async create(
        {
            ascentId,
            method,
            status,
            capturedLatitude,
            capturedLongitude,
            capturedAccuracyMeters,
            capturedAt,
            distanceToPeakMeters,
            checkedAt,
            reason,
        },
        connection
    ) {
        const executor = connection || pool;

        const sql = `
        INSERT INTO ascent_verifications (
            ascent_id,
            method,
            status,
            captured_latitude,
            captured_longitude,
            captured_accuracy_meters,
            captured_at,
            distance_to_peak_meters,
            checked_at,
            reason
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        try {
            const [result] = await executor.execute(sql, [
                ascentId,
                method,
                status,
                capturedLatitude,
                capturedLongitude,
                capturedAccuracyMeters,
                capturedAt,
                distanceToPeakMeters,
                checkedAt,
                reason,
            ]);

            return this.findById(result.insertId, executor);
        } catch (err) {
            if (
                err &&
                (err.code === 'ER_NO_REFERENCED_ROW' ||
                    err.code === 'ER_NO_REFERENCED_ROW_2')
            ) {
                const error = new Error('Ascent not found');
                error.statusCode = 404;
                throw error;
            }

            throw err;
        }
    },

    // Aquest mètode retorna una verificació pel seu identificador.
    // Serveix per recuperar el registre creat amb el mateix format que guarda la base de dades.
    async findById(id, connection) {
        const executor = connection || pool;

        const sql = `
        SELECT
            id,
            ascent_id,
            method,
            status,
            captured_latitude,
            captured_longitude,
            captured_accuracy_meters,
            captured_at,
            distance_to_peak_meters,
            checked_at,
            reason,
            created_at,
            updated_at
        FROM ascent_verifications
        WHERE id = ?
        LIMIT 1
        `;

        const [rows] = await executor.execute(sql, [id]);
        return rows[0] || null;
    },

    // Aquest mètode retorna la verificació vinculada a una ascensió concreta.
    // Serà útil per mostrar l’estat de verificació al detall o a l’historial.
    async findByAscentId(ascentId, connection) {
        const executor = connection || pool;

        const sql = `
        SELECT
            id,
            ascent_id,
            method,
            status,
            captured_latitude,
            captured_longitude,
            captured_accuracy_meters,
            captured_at,
            distance_to_peak_meters,
            checked_at,
            reason,
            created_at,
            updated_at
        FROM ascent_verifications
        WHERE ascent_id = ?
        LIMIT 1
        `;

        const [rows] = await executor.execute(sql, [ascentId]);
        return rows[0] || null;
    },
};

module.exports = AscentVerificationModel;