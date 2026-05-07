// Aquest fitxer defineix les rutes del recurs ascent-photos. Exposa
// la generació de signed URLs perquè el frontend pugui pujar fotos
// directament al bucket de GCS abans de confirmar la creació de l'ascens.
// La persistència a ascent_photos viu a ascentService dins de la
// transacció de creació de l'ascens, no es duplica en aquest recurs.
const express = require('express');
const router = express.Router();

const AscentPhotoController = require('../controllers/ascentPhotoController');
const authMiddleware = require('../middleware/authMiddleware');
const { signedUploadUrlRateLimiter } = require('../middleware/rateLimiters');

router.use(authMiddleware);

// El rate limiter evita que un usuari pugui demanar una quantitat
// desproporcionada de signed URLs i deixi blobs orfes al bucket. Cada
// signed URL és barata però no zero, i el cost real és l'emmagatzematge
// si finalment l'usuari hi puja contingut sense confirmar mai cap ascens.
router.post('/signed-upload-url', signedUploadUrlRateLimiter, AscentPhotoController.createUploadUrl);

module.exports = router;
