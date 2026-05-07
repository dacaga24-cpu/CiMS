// Ruta del dashboard. Un sol endpoint perquè la pantalla d'inici només
// necessita una petició per obtenir totes les dades que mostra.
const express = require('express');
const router = express.Router();

const DashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/', DashboardController.getDashboard);

module.exports = router;
