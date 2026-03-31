// peakRoutes.js
// Responsabilidad: Definir los endpoints de cims y asociarlos al controller.

const express = require('express');
const router = express.Router();
const peakController = require('../controllers/peakController');
// const authMiddleware = require('../middleware/authMiddleware');

// GET /api/peaks/search — Busca cims por nombre (publica)
// NOTA: Debe ir antes de /:id para evitar conflicto de rutas
router.get('/search', peakController.search);

// GET /api/peaks/altitude — Filtra cims por altitud (publica)
// NOTA: Debe ir antes de /:id para evitar conflicto de rutas
router.get('/altitude', peakController.getByAltitude);

// GET /api/peaks/region/:regionId — Cims de una comarca (publica)
router.get('/region/:regionId', peakController.getByRegion);

// GET /api/peaks/:id — Detalle de un cim (publica)
router.get('/:id', peakController.getById);

// GET /api/peaks — Lista todos los cims (publica)
router.get('/', peakController.getAll);

module.exports = router;
