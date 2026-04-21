  // Aquest fitxer defineix les rutes de les comarques.
  // És rellevant perquè connecta l'endpoint amb el controlador corresponent
  // i exposa la llista de manera pública, sense necessitat d'autenticació.
  const express = require('express');
  const router = express.Router();

  // Aquest bloc importa la lògica que resol cada acció de comarques.
  const RegionController = require('../controllers/regionController');

  // Aquesta ruta retorna la llista completa de comarques disponibles
  // perquè el frontend pugui alimentar els filtres del catàleg de cims.
  router.get('/', RegionController.list);

  // Aquest export permet utilitzar aquest conjunt de rutes dins del servidor principal.
  module.exports = router;
