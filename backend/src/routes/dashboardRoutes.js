// Aquest fitxer defineix la ruta del dashboard de l'usuari.
// Hi ha un sol endpoint perquè la pantalla d'inici només necessita una
// petició per obtenir totes les dades que mostra (repte, objectius,
// preferits i sèrie mensual).
const express = require('express');
const router = express.Router();

const DashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middleware/authMiddleware');

// L'autenticació s'aplica a totes les rutes d'aquest recurs perquè el
// dashboard sempre és personal i requereix saber qui és l'usuari.
router.use(authMiddleware);

router.get('/', DashboardController.getDashboard);

module.exports = router;
