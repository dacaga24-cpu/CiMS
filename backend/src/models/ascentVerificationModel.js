const pool = require('../config/db');

// Aquest model centralitza les dades de verificació d’una ascensió.
// Permet guardar i consultar la prova que confirma si una ascensió ha estat validada.
const AscentVerificationModel = {
    // Crea la verificació associada a una ascensió.
    // Desa la ubicació capturada, la distància al cim i el resultat de la validació.
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

    // Retorna una verificació a partir del seu identificador.
    // Serveix per recuperar el registre creat amb tota la informació guardada.
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

    // Retorna la verificació vinculada a una ascensió concreta.
    // Aquesta informació permet mostrar l’estat de validació al detall o a l’historial.
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