// authService.js
// Responsabilidad: Logica de negocio de autenticacion.
// Coordina entre el modelo User, bcrypt y jsonwebtoken.
// NO accede a req/res — no sabe que existe HTTP.

const User = require('../models/User');
// const bcrypt = require('bcrypt');
// const jwt = require('jsonwebtoken');

// Registra un nuevo usuario: valida que el email no exista, hashea la contrasena, crea el user
async function register({ firstName, lastName, email, password }) {}

// Autentica un usuario: busca por email, compara contrasena con bcrypt, genera JWT
async function login({ email, password }) {}

// Invalida la sesion del usuario (si se implementa blacklist de tokens)
async function logout(token) {}

// Inicia el proceso de recuperacion de contrasena: genera token temporal y envia email
async function forgotPassword(email) {}

module.exports = { register, login, logout, forgotPassword };
