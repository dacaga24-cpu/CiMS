// Aquest fitxer defineix la ruta d'estadístiques personals de l'usuari.
// Hi ha un sol endpoint perquè la pantalla d'estadístiques només necessita
// una única crida per obtenir totes les dades del resum.
const express = require('express');
const router = express.Router();

const StatsController = require('../controllers/statsController');
const authMiddleware = require('../middleware/authMiddleware');

// L'autenticació s'aplica a totes les rutes d'aquest recurs perquè les
// estadístiques sempre són personals i requereixen saber qui és l'usuari.
router.use(authMiddleware);

router.get('/', StatsController.getUserStats);

module.exports = router;
