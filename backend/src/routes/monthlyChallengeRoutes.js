// Aquest fitxer defineix les rutes del repte mensual. Només s'exposa la
// lectura del repte actiu del mes en curs, perquè el progrés és sempre
// personal i la generació de la plantilla i el recompute es fan de manera
// automàtica des del servei (no hi ha endpoints d'escriptura manual).
const express = require('express');
const router = express.Router();

const MonthlyChallengeController = require('../controllers/monthlyChallengeController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/current', MonthlyChallengeController.getCurrent);

module.exports = router;
