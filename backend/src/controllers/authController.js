// authController.js
// Responsabilidad: Recibir peticiones HTTP de autenticacion, extraer parametros,
// llamar al authService y devolver la respuesta HTTP.
// NO contiene logica de negocio — solo delega al service.

const authService = require('../services/authService');

// POST /api/auth/register — Registra un nuevo usuario
async function register(req, res, next) {}

// POST /api/auth/login — Autentica un usuario y devuelve JWT
async function login(req, res, next) {}

// POST /api/auth/logout — Cierra la sesion del usuario
async function logout(req, res, next) {}

// POST /api/auth/forgot-password — Inicia recuperacion de contrasena
async function forgotPassword(req, res, next) {}

module.exports = { register, login, logout, forgotPassword };
