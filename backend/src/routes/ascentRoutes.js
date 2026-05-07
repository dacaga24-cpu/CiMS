// Rutes d'ascensions (/api/ascents). Totes privades.
const express = require('express');
const router = express.Router();

const AscentController = require('../controllers/ascentController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

// /peak/:peakId va abans que /:ascentId per garantir que Express no
// interpreti "peak" com un ascentId.
router.get('/peak/:peakId', AscentController.getByUserAndPeak);
router.get('/:ascentId/photos', AscentController.getPhotosForAscent);
router.get('/', AscentController.getByUser);
router.post('/', AscentController.create);
router.put('/:ascentId', AscentController.update);
router.delete('/:ascentId', AscentController.remove);

module.exports = router;
