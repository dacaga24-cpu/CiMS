// Aquest fitxer defineix les rutes de l’estat personal dels cims.
// Totes requereixen autenticació perquè cada usuari només pugui gestionar les seves pròpies marques.
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const PeakStatusController = require('../controllers/peakStatusController');

// Aquest middleware protegeix totes les rutes d’aquest recurs.
// Les peticions sense token vàlid no arriben als controladors.
router.use(authMiddleware);

// Aquestes rutes permeten consultar, crear, actualitzar i eliminar l’estat personal dels cims.
// La ruta arrel retorna tots els estats de l’usuari i les rutes amb peakId actuen sobre un cim concret.
router.get('/', PeakStatusController.getStatusByUser);
router.get('/:peakId', PeakStatusController.getByUserAndPeak);
router.put('/:peakId', PeakStatusController.upsertPeakStatus);
router.delete('/:peakId', PeakStatusController.removeByUserAndPeak);

module.exports = router;