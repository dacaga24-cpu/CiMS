// Aquest fitxer defineix la ruta del dashboard de l’usuari.
// Permet obtenir en una sola petició el resum principal que es mostra a la pantalla d’inici.
const express = require('express');
const router = express.Router();

const DashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middleware/authMiddleware');

// Aquest middleware protegeix totes les rutes del dashboard.
// El resum és personal i sempre necessita identificar l’usuari autenticat.
router.use(authMiddleware);

// Retorna les dades principals del dashboard de l’usuari.
router.get('/', DashboardController.getDashboard);

module.exports = router;