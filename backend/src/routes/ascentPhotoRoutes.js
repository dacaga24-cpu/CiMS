// Aquest fitxer defineix les rutes relacionades amb les fotos d’ascensions.
// Permet consultar la galeria, generar URLs de pujada i eliminar imatges pròpies.
const express = require('express');
const router = express.Router();

const AscentPhotoController = require('../controllers/ascentPhotoController');
const authMiddleware = require('../middleware/authMiddleware');
const { signedUploadUrlRateLimiter } = require('../middleware/rateLimiters');

// Aquestes rutes gestionen les fotos d’ascensions de l’usuari autenticat.
// L’autenticació garanteix que cada usuari només pugui accedir a les seves pròpies imatges.
router.use(authMiddleware);

// Retorna la galeria paginada de fotos de l’usuari.
// Aquesta càrrega permet mostrar moltes imatges sense demanar-les totes de cop.
router.get('/me', AscentPhotoController.getUserGallery);

// Genera una URL temporal per pujar fotos d’ascensions.
// El limitador evita un ús excessiu de pujades cap a l’emmagatzematge.
router.post(
  '/signed-upload-url',
  signedUploadUrlRateLimiter,
  AscentPhotoController.createUploadUrl
);

// Elimina una foto concreta de l’usuari autenticat.
// El servei comprova la propietat de la imatge abans de fer l’eliminació.
router.delete('/:photoId', AscentPhotoController.deletePhoto);

module.exports = router;