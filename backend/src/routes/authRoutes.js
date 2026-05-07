// Rutes d'autenticació (/api/auth).
const express = require('express');
const router = express.Router();

const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  loginRateLimiter,
  forgotPasswordRateLimiter,
  registerRateLimiter,
  resetPasswordRateLimiter,
} = require('../middleware/rateLimiters');

// Endpoints públics. Cadascun amb el seu rate limiter perquè són els punts
// més exposats a atacs automàtics (força bruta, abús de SendGrid, creació
// massiva de comptes, intent d'endevinar tokens).
router.post('/register', registerRateLimiter, AuthController.register);
router.post('/login', loginRateLimiter, AuthController.login);
router.post('/forgot-password', forgotPasswordRateLimiter, AuthController.requestPasswordReset);
router.post('/reset-password', resetPasswordRateLimiter, AuthController.resetPassword);

// Privat: requereix sessió vàlida.
router.get('/profile', authMiddleware, AuthController.getProfile);

module.exports = router;
