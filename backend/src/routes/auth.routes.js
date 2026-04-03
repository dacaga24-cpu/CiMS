const express = require('express');
const { body } = require('express-validator');
const AuthController = require('../controllers/authController');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Validacions per a registre
const registerValidation = [
  body('username')
    .trim()
    .isLength({ min: 3, max: 50 })
    .withMessage('El nom d\'usuari ha de tenir entre 3 i 50 caràcters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email no vàlid'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('La contrasenya ha de tenir almenys 6 caràcters')
];

// Validacions per a login
const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email no vàlid'),
  body('password')
    .notEmpty()
    .withMessage('La contrasenya és obligatòria')
];

// @route   POST /api/auth/register
// @desc    Registrar nou usuari
// @access  Public
router.post('/register', registerValidation, AuthController.register);

// @route   POST /api/auth/login
// @desc    Iniciar sessió
// @access  Public
router.post('/login', loginValidation, AuthController.login);

// @route   GET /api/auth/profile
// @desc    Obtenir perfil de l'usuari autenticat
// @access  Private
router.get('/profile', authMiddleware, AuthController.getProfile);

// @route   GET /api/auth/verify
// @desc    Verificar si el token és vàlid
// @access  Private
router.get('/verify', authMiddleware, AuthController.verifyToken);

module.exports = router;
