  // Aquest fitxer defineix les rutes del catàleg de cims. Totes són
  // públiques: el catàleg ha de ser consultable sense haver d'iniciar
  // sessió perquè és la pàgina d'entrada de l'aplicació.
  const express = require('express');
  const router = express.Router();

  const PeakController = require('../controllers/peakController');

  // /map ha d'anar abans que /:id perquè Express resol les rutes per ordre
  // de declaració: si fos al revés, la cadena "map" s'interpretaria com un
  // identificador i mai s'arribaria al handler del mapa.
  router.get('/', PeakController.list);
  router.get('/map', PeakController.listForMap);
  router.get('/:id', PeakController.getById);

  module.exports = router;
