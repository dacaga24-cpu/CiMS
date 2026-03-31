// User.js
// Responsabilidad: Encapsular las queries SQL de la entidad users.
// NO contiene logica de negocio (validaciones, reglas) — eso va en services.

const pool = require('../config/db');

// Busca un usuario por su ID
// Query: SELECT * FROM users WHERE id = ?
async function findById(id) {}

// Busca un usuario por su email
// Query: SELECT * FROM users WHERE email = ?
async function findByEmail(email) {}

// Devuelve todos los usuarios
// Query: SELECT * FROM users
async function findAll() {}

// Crea un nuevo usuario
// Query: INSERT INTO users (first_name, last_name, email, password) VALUES (?, ?, ?, ?)
async function create({ firstName, lastName, email, password }) {}

// Actualiza un usuario existente
// Query: UPDATE users SET first_name = ?, last_name = ?, email = ? WHERE id = ?
async function update(id, { firstName, lastName, email }) {}

// Elimina un usuario por su ID
// Query: DELETE FROM users WHERE id = ?
async function remove(id) {}

module.exports = { findById, findByEmail, findAll, create, update, remove };
