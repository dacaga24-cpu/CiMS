// Aquest fitxer defineix les rutes públiques de les comarques.
// Permet al frontend obtenir la llista necessària per construir els filtres del catàleg.
const express = require('express');
const router = express.Router();

const RegionController = require('../controllers/regionController');

// Retorna la llista completa de comarques disponibles.
// Aquesta informació s’utilitza principalment als filtres del catàleg de cims.
router.get('/', RegionController.list);

// Aquest export permet utilitzar aquestes rutes dins del servidor principal.
module.exports = router;