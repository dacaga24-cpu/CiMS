// Ascent.js
// Responsabilidad: Encapsular las queries SQL de la entidad ascents.
// NO contiene logica de negocio — eso va en services.

const pool = require('../config/db');

// Busca una ascension por su ID
// Query: SELECT * FROM ascents WHERE id = ?
async function findById(id) {}

// Devuelve todas las ascensiones de un usuario
// Query: SELECT a.*, p.name AS peak_name FROM ascents a JOIN peaks p ON a.peak_id = p.id WHERE a.user_id = ?
async function findByUserId(userId) {}

// Devuelve todas las ascensiones a un cim
// Query: SELECT a.*, u.first_name, u.last_name FROM ascents a JOIN users u ON a.user_id = u.id WHERE a.peak_id = ?
async function findByPeakId(peakId) {}

// Crea una nueva ascension
// Query: INSERT INTO ascents (user_id, peak_id, ascent_date, notes) VALUES (?, ?, ?, ?)
async function create({ userId, peakId, ascentDate, notes }) {}

// Actualiza una ascension existente
// Query: UPDATE ascents SET ascent_date = ?, notes = ? WHERE id = ?
async function update(id, { ascentDate, notes }) {}

// Elimina una ascension por su ID
// Query: DELETE FROM ascents WHERE id = ?
async function remove(id) {}

module.exports = { findById, findByUserId, findByPeakId, create, update, remove };
