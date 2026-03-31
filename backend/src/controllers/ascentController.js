// ascentController.js
// Responsabilidad: Recibir peticiones HTTP sobre ascensiones, extraer parametros,
// llamar al ascentService y devolver la respuesta HTTP.
// NO contiene logica de negocio — solo delega al service.

const ascentService = require('../services/ascentService');

// POST /api/ascents — Registra una nueva ascension
async function create(req, res, next) {}

// PUT /api/ascents/:id — Actualiza una ascension existente
async function update(req, res, next) {}

// DELETE /api/ascents/:id — Elimina una ascension
async function remove(req, res, next) {}

// GET /api/ascents/user/:userId — Devuelve las ascensiones de un usuario
async function getByUser(req, res, next) {}

// GET /api/ascents/peak/:peakId — Devuelve las ascensiones a un cim
async function getByPeak(req, res, next) {}

module.exports = { create, update, remove, getByUser, getByPeak };
