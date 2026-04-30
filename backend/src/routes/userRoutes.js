// Aquest fitxer defineix les rutes relacionades amb el perfil i la gestió del compte.
// És rellevant perquè agrupa sota /api/users tots els endpoints que un usuari
// autenticat pot utilitzar per consultar i modificar les seves pròpies dades.
const express = require('express');
const router = express.Router();

const UserController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

// Totes les rutes d'aquest fitxer requereixen autenticació.
// El middleware es registra a nivell de router perquè s'apliqui
// automàticament a tots els endpoints sense haver de repetir-lo.
router.use(authMiddleware);

// Aquest endpoint permet a l'usuari consultar les seves dades de perfil.
router.get('/profile', UserController.getProfile);

module.exports = router;