// Rutes del catàleg de cims (/api/peaks). Públiques: el catàleg ha de ser
// consultable sense iniciar sessió.
const express = require('express');
const router = express.Router();

const PeakController = require('../controllers/peakController');

// /map abans que /:id perquè Express resol per ordre: si fos al revés,
// "map" s'interpretaria com un id i mai s'arribaria al handler del mapa.
router.get('/', PeakController.list);
router.get('/map', PeakController.listForMap);
router.get('/:id', PeakController.getById);

module.exports = router;
