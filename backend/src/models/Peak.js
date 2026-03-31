// Peak.js
// Responsabilidad: Encapsular las queries SQL de la entidad peaks.
// NO contiene logica de negocio — eso va en services.

const pool = require('../config/db');

// Busca un cim por su ID
// Query: SELECT p.*, r.name AS region_name FROM peaks p JOIN regions r ON p.region_id = r.id WHERE p.id = ?
async function findById(id) {}

// Devuelve todos los cims
// Query: SELECT p.*, r.name AS region_name FROM peaks p JOIN regions r ON p.region_id = r.id
async function findAll() {}

// Devuelve los cims de una comarca
// Query: SELECT * FROM peaks WHERE region_id = ?
async function findByRegionId(regionId) {}

// Busca cims por rango de altitud
// Query: SELECT * FROM peaks WHERE altitude BETWEEN ? AND ? ORDER BY altitude DESC
async function findByAltitudeRange(minAltitude, maxAltitude) {}

// Busca cims por nombre (busqueda parcial)
// Query: SELECT * FROM peaks WHERE name LIKE ?
async function search(query) {}

// Crea un nuevo cim
// Query: INSERT INTO peaks (name, altitude, latitude, longitude, region_id) VALUES (?, ?, ?, ?, ?)
async function create({ name, altitude, latitude, longitude, regionId }) {}

// Actualiza un cim existente
// Query: UPDATE peaks SET name = ?, altitude = ?, latitude = ?, longitude = ?, region_id = ? WHERE id = ?
async function update(id, { name, altitude, latitude, longitude, regionId }) {}

// Elimina un cim por su ID
// Query: DELETE FROM peaks WHERE id = ?
async function remove(id) {}

module.exports = { findById, findAll, findByRegionId, findByAltitudeRange, search, create, update, remove };
