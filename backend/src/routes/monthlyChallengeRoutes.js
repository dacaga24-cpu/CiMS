// Rutes del repte mensual. Només lectura: la generació de la plantilla i el
// recompute es fan automàticament des del servei.
const express = require('express');
const router = express.Router();

const MonthlyChallengeController = require('../controllers/monthlyChallengeController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/current', MonthlyChallengeController.getCurrent);

module.exports = router;
