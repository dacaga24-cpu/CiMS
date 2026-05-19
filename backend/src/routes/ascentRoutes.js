// Aquest fitxer defineix les rutes relacionades amb les ascensions dels usuaris.
// Totes elles estan protegides per authMiddleware perquè cada usuari només
// pot consultar i modificar les seves pròpies ascensions.
const express = require('express');
const router = express.Router();

const AscentController = require('../controllers/ascentController');
const authMiddleware = require('../middleware/authMiddleware');

// El middleware s'aplica a totes les rutes d'aquest fitxer, ja que no n'hi ha
// cap de pública. Centralitzar-ho aquí evita oblits si en el futur s'afegeixen
// endpoints nous a aquest mateix recurs.
router.use(authMiddleware);

// Aquestes rutes específiques han d'anar abans de les rutes amb paràmetres.
// Això evita que Express interpreti valors com "verified" o "peak" com si fossin ascentId.
router.get('/peak/:peakId', AscentController.getByUserAndPeak);
router.get('/:ascentId/photos', AscentController.getPhotosForAscent);
router.post('/verified', AscentController.createVerified);

// Aquestes rutes gestionen les operacions generals sobre ascensions.
router.get('/', AscentController.getByUser);
router.post('/', AscentController.create);
router.put('/:ascentId', AscentController.update);
router.delete('/:ascentId', AscentController.remove);

module.exports = router;