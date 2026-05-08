const express = require('express');
const router = express.Router();

const AscentPhotoController = require('../controllers/ascentPhotoController');
const authMiddleware = require('../middleware/authMiddleware');
const { signedUploadUrlRateLimiter } = require('../middleware/rateLimiters');

// Totes les rutes de fotos requereixen autenticació.
// Això garanteix que cada usuari només pugui consultar o preparar imatges pròpies.
router.use(authMiddleware);

// Retorna les fotos de l'usuari autenticat en format paginat.
// S'utilitza per carregar la galeria completa sense demanar totes les imatges de cop.
router.get('/me', AscentPhotoController.getUserGallery);

// Genera una URL temporal de pujada per afegir fotos a una ascensió.
router.post(
  '/signed-upload-url',
  signedUploadUrlRateLimiter,
  AscentPhotoController.createUploadUrl
);

module.exports = router;