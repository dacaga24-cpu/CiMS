// authRoutes.js
// Responsabilidad: Definir los endpoints de autenticacion y asociarlos al controller.
// Todas las rutas de auth son publicas (no requieren authMiddleware).

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// POST /api/auth/register — Registro de nuevo usuario (publica)
router.post('/register', authController.register);

// POST /api/auth/login — Login de usuario (publica)
router.post('/login', authController.login);

// POST /api/auth/logout — Logout de usuario (publica)
router.post('/logout', authController.logout);

// POST /api/auth/forgot-password — Recuperacion de contrasena (publica)
router.post('/forgot-password', authController.forgotPassword);

module.exports = router;
