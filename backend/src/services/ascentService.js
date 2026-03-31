// ascentService.js
// Responsabilidad: Logica de negocio relacionada con las ascensiones.
// Coordina con los modelos Ascent y PeakStatus.
// NO accede a req/res — no sabe que existe HTTP.

const Ascent = require('../models/Ascent');
// const PeakStatus = require('../models/PeakStatus');

// Registra una nueva ascension y actualiza el estado del cim (is_completed)
async function createAscent({ userId, peakId, ascentDate, notes }) {}

// Actualiza una ascension existente (solo si pertenece al usuario)
async function updateAscent(id, userId, { ascentDate, notes }) {}

// Elimina una ascension (solo si pertenece al usuario)
async function deleteAscent(id, userId) {}

// Devuelve las ascensiones de un usuario
async function getUserAscents(userId) {}

// Devuelve las ascensiones a un cim especifico
async function getPeakAscents(peakId) {}

module.exports = { createAscent, updateAscent, deleteAscent, getUserAscents, getPeakAscents };
