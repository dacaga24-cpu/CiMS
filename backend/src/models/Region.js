// Region.js
// Responsabilidad: Encapsular las queries SQL de la entidad regions.
// NO contiene logica de negocio — eso va en services.

const pool = require('../config/db');

// Busca una comarca por su ID
// Query: SELECT * FROM regions WHERE id = ?
async function findById(id) {}

// Devuelve todas las comarcas
// Query: SELECT * FROM regions ORDER BY name
async function findAll() {}

// Crea una nueva comarca
// Query: INSERT INTO regions (name) VALUES (?)
async function create(name) {}

module.exports = { findById, findAll, create };
