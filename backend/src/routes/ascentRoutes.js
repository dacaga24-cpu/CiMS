// ascentRoutes.js
// Responsabilidad: Definir los endpoints de ascensiones y asociarlos al controller.
// Todas las rutas de ascensiones requieren autenticacion (authMiddleware).

const express = require('express');
const router = express.Router();
const ascentController = require('../controllers/ascentController');
const authMiddleware = require('../middleware/authMiddleware');

// Todas las rutas de ascensiones requieren autenticacion
router.use(authMiddleware);

// POST /api/ascents — Registrar nueva ascension (protegida)
router.post('/', ascentController.create);

// PUT /api/ascents/:id — Actualizar ascension (protegida)
router.put('/:id', ascentController.update);

// DELETE /api/ascents/:id — Eliminar ascension (protegida)
router.delete('/:id', ascentController.remove);

// GET /api/ascents/user/:userId — Ascensiones de un usuario (protegida)
router.get('/user/:userId', ascentController.getByUser);

// GET /api/ascents/peak/:peakId — Ascensiones a un cim (protegida)
router.get('/peak/:peakId', ascentController.getByPeak);

module.exports = router;
