// Aquest fitxer defineix la ruta d’estadístiques personals de l’usuari.
// Permet obtenir en una sola petició totes les dades necessàries per mostrar el resum de progrés.
const express = require('express');
const router = express.Router();

const StatsController = require('../controllers/statsController');
const authMiddleware = require('../middleware/authMiddleware');

// Aquest middleware protegeix totes les rutes d’estadístiques.
// Les dades són personals i sempre necessiten identificar l’usuari autenticat.
router.use(authMiddleware);

// Retorna el resum d’estadístiques de l’usuari.
router.get('/', StatsController.getUserStats);

module.exports = router;