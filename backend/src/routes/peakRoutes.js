  // Aquest fitxer defineix les rutes del catàleg de cims. Totes són
  // públiques: el catàleg ha de ser consultable sense haver d'iniciar
  // sessió perquè és la pàgina d'entrada de l'aplicació. Tot i això, la
  // llista i la vista de mapa apliquen `optionalAuthMiddleware`: si arriba
  // un token vàlid podem enriquir la resposta filtrant per l'estat
  // personal de l'usuari (`?status=`). Si no n'hi ha, ignorem el filtre i
  // retornem el catàleg públic com sempre.
  const express = require('express');
  const router = express.Router();

  const PeakController = require('../controllers/peakController');
  const optionalAuthMiddleware = require('../middleware/optionalAuthMiddleware');

  // /map ha d'anar abans que /:id perquè Express resol les rutes per ordre
  // de declaració: si fos al revés, la cadena "map" s'interpretaria com un
  // identificador i mai s'arribaria al handler del mapa.
  router.get('/', optionalAuthMiddleware, PeakController.list);
  router.get('/map', optionalAuthMiddleware, PeakController.listForMap);
  router.get('/:id', PeakController.getById);

  module.exports = router;
