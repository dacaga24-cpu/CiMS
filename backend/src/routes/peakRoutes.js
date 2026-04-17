  // Aquest fitxer defineix les rutes del catàleg de cims.
  // És rellevant perquè connecta cada endpoint amb el controlador corresponent
  // i exposa el catàleg de manera pública, sense necessitat d'autenticació.
  const express = require('express');
  const router = express.Router();

  // Aquest bloc importa la lògica que resol cada acció del catàleg.
  const PeakController = require('../controllers/peakController');

  // Aquest bloc agrupa les rutes públiques del catàleg.
  // La ruta arrel retorna la llista (amb filtres opcionals via query string)
  // i la ruta amb identificador retorna el detall d'un cim concret.
  router.get('/', PeakController.list);
  router.get('/:id', PeakController.getById);

  // Aquest export permet utilitzar aquest conjunt de rutes dins del servidor principal.
  module.exports = router;
