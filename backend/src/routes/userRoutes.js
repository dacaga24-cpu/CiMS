// Aquest fitxer defineix les rutes relacionades amb el perfil i la gestió del compte.
// Agrupa les accions que permeten a l’usuari consultar i modificar les seves pròpies dades.
const express = require('express');
const router = express.Router();

const UserController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  changePasswordRateLimiter,
  signedUploadUrlRateLimiter,
} = require('../middleware/rateLimiters');

// Aquest middleware protegeix totes les rutes d’aquest recurs.
// Això garanteix que només l’usuari autenticat pugui operar sobre el seu compte.
router.use(authMiddleware);

// Canvia la contrasenya de l’usuari autenticat.
// El limitador redueix el risc d’intents repetits sobre una acció sensible.
router.put('/password', changePasswordRateLimiter, UserController.changePassword);

// Retorna les dades del perfil de l’usuari autenticat.
router.get('/profile', UserController.getProfile);

// Actualitza el nom i el cognom del perfil de l’usuari.
router.put('/profile', UserController.updateProfile);

// Desactiva el compte de l’usuari de manera voluntària.
router.delete('/account', UserController.deleteAccount);

// Aquestes rutes gestionen la foto de perfil.
// El frontend demana una URL temporal, puja la imatge i després confirma la ruta al backend.
router.post(
  '/profile-photo/signed-upload-url',
  signedUploadUrlRateLimiter,
  UserController.createProfilePhotoUploadUrl
);
router.put('/profile-photo', signedUploadUrlRateLimiter, UserController.setProfilePhoto);
router.delete('/profile-photo', signedUploadUrlRateLimiter, UserController.deleteProfilePhoto);

module.exports = router;