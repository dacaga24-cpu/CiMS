// Aquest fitxer defineix les rutes públiques del catàleg de cims.
// Si la petició inclou un token vàlid, algunes consultes poden incorporar l’estat personal de l’usuari.
const express = require('express');
const router = express.Router();

const PeakController = require('../controllers/peakController');
const optionalAuthMiddleware = require('../middleware/optionalAuthMiddleware');

// La ruta del mapa s’ha de declarar abans de la ruta amb identificador.
// Això evita que Express interpreti "map" com si fos l’id d’un cim.
router.get('/', optionalAuthMiddleware, PeakController.list);
router.get('/map', optionalAuthMiddleware, PeakController.listForMap);
router.get('/:id', PeakController.getById);

module.exports = router;