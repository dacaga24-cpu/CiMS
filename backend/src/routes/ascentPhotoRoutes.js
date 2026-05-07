// Rutes del recurs ascent-photos. Exposa la generació de signed URLs perquè
// el frontend pugi fotos directament a GCS. La persistència a ascent_photos
// viu a ascentService dins de la transacció de creació de l'ascens.
const express = require('express');
const router = express.Router();

const AscentPhotoController = require('../controllers/ascentPhotoController');
const authMiddleware = require('../middleware/authMiddleware');
const { signedUploadUrlRateLimiter } = require('../middleware/rateLimiters');

router.use(authMiddleware);

// El rate limiter evita que un usuari demani signed URLs en massa i deixi
// blobs orfes al bucket sense confirmar mai cap ascens.
router.post('/signed-upload-url', signedUploadUrlRateLimiter, AscentPhotoController.createUploadUrl);

module.exports = router;
