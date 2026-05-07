// Aquest fitxer defineix les rutes relacionades amb el perfil i la gestió del compte.
// És rellevant perquè agrupa sota /api/users tots els endpoints que un usuari
// autenticat pot utilitzar per consultar i modificar les seves pròpies dades.
const express = require('express');
const router = express.Router();

const UserController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  changePasswordRateLimiter,
  signedUploadUrlRateLimiter,
} = require('../middleware/rateLimiters');

// Totes les rutes d'aquest fitxer requereixen autenticació.
// El middleware es registra a nivell de router perquè s'apliqui
// automàticament a tots els endpoints sense haver de repetir-lo.
router.use(authMiddleware);

// Ruta per canviar la contrasenya amb limitació de taxa.
router.put('/password', changePasswordRateLimiter, UserController.changePassword);

// Aquest endpoint permet a l'usuari consultar les seves dades de perfil.
router.get('/profile', UserController.getProfile);

// Aquest endpoint permet a l'usuari actualitzar el nom i el cognom del seu compte.
router.put('/profile', UserController.updateProfile);

// Aquest endpoint permet a l'usuari desactivar el seu compte de manera voluntària.
router.delete('/account', UserController.deleteAccount);

// Endpoints de la foto de perfil. La pujada segueix el mateix patró que les
// fotos d'ascens: el client demana una signed URL, puja directament a GCS
// i després confirma el path al backend perquè quedi enllaçat al perfil.
// El rate limiter es comparteix amb el d'ascent-photos i s'aplica també
// als endpoints de mutació (PUT i DELETE) perquè cada operació toca BD
// i fa una o dues operacions a GCS (objectExists, deleteObject,
// generateSignedDownloadUrl); sense límit, un usuari autenticat podria
// abusar-ne i saturar les quotes del bucket.
router.post(
  '/profile-photo/signed-upload-url',
  signedUploadUrlRateLimiter,
  UserController.createProfilePhotoUploadUrl
);
router.put('/profile-photo', signedUploadUrlRateLimiter, UserController.setProfilePhoto);
router.delete('/profile-photo', signedUploadUrlRateLimiter, UserController.deleteProfilePhoto);

module.exports = router;