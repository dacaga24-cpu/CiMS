// Framework and router
const express = require('express');
const router = express.Router();

// Controladors i middleware
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Rutes públiques
router.post('/register', AuthController.register);
router.post('/login', AuthController.login);
router.post('/forgot-password', AuthController.requestPasswordReset);
router.post('/reset-password', AuthController.resetPassword);

// Rutes protegides (requereixen autenticació)
router.get('/profile', authMiddleware, AuthController.getProfile);

module.exports = router;