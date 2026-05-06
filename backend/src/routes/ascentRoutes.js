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

// La ruta més específica (/peak/:peakId) ha d'anar abans que les que
// reben paràmetres genèrics, per garantir que Express l'identifica
// correctament en lloc d'intentar interpretar "peak" com un ascentId.
// La ruta /:ascentId/photos s'agrupa amb les altres rutes de lectura
// per claredat de l'estructura del fitxer.
router.get('/peak/:peakId', AscentController.getByUserAndPeak);
router.get('/:ascentId/photos', AscentController.getPhotosForAscent);
router.get('/', AscentController.getByUser);
router.post('/', AscentController.create);
router.put('/:ascentId', AscentController.update);
router.delete('/:ascentId', AscentController.remove);

module.exports = router;
