// PeakStatus.js
// Responsabilidad: Encapsular las queries SQL de la entidad peak_status.
// NO contiene logica de negocio — eso va en services.

const pool = require('../config/db');

// Busca el estado de un cim para un usuario
// Query: SELECT * FROM peak_status WHERE user_id = ? AND peak_id = ?
async function findByUserAndPeak(userId, peakId) {}

// Devuelve todos los estados de cims de un usuario
// Query: SELECT ps.*, p.name AS peak_name FROM peak_status ps JOIN peaks p ON ps.peak_id = p.id WHERE ps.user_id = ?
async function findByUserId(userId) {}

// Crea o actualiza el estado de un cim para un usuario (upsert)
// Query: INSERT INTO peak_status (user_id, peak_id, is_completed, is_target, is_favorite) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE ...
async function upsert({ userId, peakId, isCompleted, isTarget, isFavorite }) {}

// Elimina el estado de un cim para un usuario
// Query: DELETE FROM peak_status WHERE user_id = ? AND peak_id = ?
async function remove(userId, peakId) {}

module.exports = { findByUserAndPeak, findByUserId, upsert, remove };
