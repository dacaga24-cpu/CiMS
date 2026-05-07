// Rutes de l'estat personal dels cims (/api/peak-status). Totes privades.
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const PeakStatusController = require('../controllers/peakStatusController');

router.use(authMiddleware);

// /        : tots els estats de l'usuari
// /:peakId : GET = estat actual, PUT = upsert, DELETE = eliminar
router.get('/', PeakStatusController.getStatusByUser);
router.get('/:peakId', PeakStatusController.getByUserAndPeak);
router.put('/:peakId', PeakStatusController.upsertPeakStatus);
router.delete('/:peakId', PeakStatusController.removeByUserAndPeak);

module.exports = router;
