// peakController.js
// Responsabilidad: Recibir peticiones HTTP sobre cims, extraer parametros,
// llamar al peakService y devolver la respuesta HTTP.
// NO contiene logica de negocio — solo delega al service.

const peakService = require('../services/peakService');

// GET /api/peaks — Devuelve todos los cims
async function getAll(req, res, next) {}

// GET /api/peaks/:id — Devuelve un cim por ID
async function getById(req, res, next) {}

// GET /api/peaks/region/:regionId — Devuelve cims de una comarca
async function getByRegion(req, res, next) {}

// GET /api/peaks/altitude — Devuelve cims filtrados por altitud (query params: min, max)
async function getByAltitude(req, res, next) {}

// GET /api/peaks/search — Busca cims por nombre (query param: q)
async function search(req, res, next) {}

module.exports = { getAll, getById, getByRegion, getByAltitude, search };
