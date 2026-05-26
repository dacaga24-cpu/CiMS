// Aquest fitxer defineix les rutes relacionades amb l’autenticació.
// Connecta cada endpoint amb el controlador corresponent i separa les accions públiques de les protegides.
const express = require('express');
const router = express.Router();

// Aquest bloc importa el controlador d’autenticació, el middleware de sessió i els limitadors de peticions.
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  loginRateLimiter,
  forgotPasswordRateLimiter,
  registerRateLimiter,
  resetPasswordRateLimiter,
} = require('../middleware/rateLimiters');

// Aquestes rutes públiques permeten registrar-se, iniciar sessió i recuperar la contrasenya.
// Els limitadors redueixen el risc d’abusos en punts exposats del sistema.
router.post('/register', registerRateLimiter, AuthController.register);
router.post('/login', loginRateLimiter, AuthController.login);
router.post('/forgot-password', forgotPasswordRateLimiter, AuthController.requestPasswordReset);
router.post('/reset-password', resetPasswordRateLimiter, AuthController.resetPassword);

// Aquesta ruta retorna el perfil de l’usuari autenticat.
// Abans d’arribar al controlador, es comprova que la sessió sigui vàlida.
router.get('/profile', authMiddleware, AuthController.getProfile);

// Aquest export permet utilitzar aquestes rutes dins del servidor principal.
module.exports = router;