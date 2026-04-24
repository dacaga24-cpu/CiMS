// Aquest fitxer defineix les rutes de l'estat personal dels cims per usuari.
// Totes les rutes estan protegides pel middleware d'autenticació,
// de manera que només els usuaris amb un token vàlid hi poden accedir.
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const PeakStatusController = require('../controllers/peakStatusController');

// Aquest bloc aplica el middleware d'autenticació a totes les rutes d'aquest router.
// Qualsevol petició sense token vàlid rep un 401 abans d'arribar al controlador.
router.use(authMiddleware);

// Aquest bloc agrupa les rutes de l'estat personal dels cims.
// La ruta arrel retorna tots els estats de l'usuari autenticat.
// Les rutes amb identificador de cim operen sobre un estat concret:
//   GET    recupera l'estat actual d'un cim per a l'usuari
//   PUT    crea o actualitza l'estat d'un cim per a l'usuari (upsert)
//   DELETE elimina l'estat d'un cim per a l'usuari
router.get('/', PeakStatusController.getStatusByUser);
router.get('/:peakId', PeakStatusController.getByUserAndPeak);
router.put('/:peakId', PeakStatusController.upsertPeakStatus);
router.delete('/:peakId', PeakStatusController.removeByUserAndPeak);

module.exports = router;
