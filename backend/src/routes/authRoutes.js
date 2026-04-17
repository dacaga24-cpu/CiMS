// Aquest fitxer defineix les rutes relacionades amb l’autenticació i l’accés al perfil.
// És rellevant perquè connecta cada endpoint amb el controlador corresponent
// i indica quines accions són públiques i quines necessiten autenticació.
const express = require('express');
const router = express.Router();

// Aquest bloc importa la lògica que resol cada acció d’autenticació
// i el sistema que protegeix les rutes privades.
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Aquest bloc agrupa les rutes públiques del sistema.
// Permeten registrar-se, iniciar sessió i gestionar el procés de recuperació de contrasenya
// sense necessitat d’haver accedit prèviament a l’aplicació.
router.post('/register', AuthController.register);
router.post('/login', AuthController.login);
router.post('/forgot-password', AuthController.requestPasswordReset);
router.post('/reset-password', AuthController.resetPassword);

// Aquesta ruta només es pot consultar si l’usuari està autenticat.
// Abans d’arribar al controlador, es comprova que la petició porti una sessió vàlida.
router.get('/profile', authMiddleware, AuthController.getProfile);

// Aquest export permet utilitzar aquest conjunt de rutes dins del servidor principal.
module.exports = router;