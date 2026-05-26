// Aquest fitxer defineix les rutes relacionades amb les ascensions.
// Totes les rutes requereixen autenticació per protegir l’historial personal de cada usuari.
const express = require('express');
const router = express.Router();

const AscentController = require('../controllers/ascentController');
const authMiddleware = require('../middleware/authMiddleware');

// Aquest middleware protegeix totes les rutes d’aquest recurs.
// Això evita repetir la mateixa comprovació d’autenticació a cada endpoint.
router.use(authMiddleware);

// Aquestes rutes específiques es declaren abans de les rutes amb paràmetres.
// Això evita conflictes d’interpretació amb identificadors dinàmics.
router.get('/peak/:peakId', AscentController.getByUserAndPeak);
router.get('/:ascentId/photos', AscentController.getPhotosForAscent);
router.post('/:ascentId/photos', AscentController.addPhotosToAscent);
router.post('/verified', AscentController.createVerified);

// Aquestes rutes gestionen les operacions principals sobre ascensions.
// Permeten consultar, crear, editar i eliminar registres de l’usuari autenticat.
router.get('/', AscentController.getByUser);
router.post('/', AscentController.create);
router.put('/:ascentId', AscentController.update);
router.delete('/:ascentId', AscentController.remove);

module.exports = router;