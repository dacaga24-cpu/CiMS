// Aquest fitxer defineix les rutes relacionades amb el repte mensual.
// Permet consultar el repte actiu i el progrés personal de l’usuari autenticat.
const express = require('express');
const router = express.Router();

const MonthlyChallengeController = require('../controllers/monthlyChallengeController');
const authMiddleware = require('../middleware/authMiddleware');

// Aquest middleware protegeix totes les rutes del repte mensual.
// El progrés és personal i necessita identificar l’usuari autenticat.
router.use(authMiddleware);

// Retorna el repte mensual actual de l’usuari.
router.get('/current', MonthlyChallengeController.getCurrent);

module.exports = router;