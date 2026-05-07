// Rutes de perfil i gestió del compte (/api/users).
const express = require('express');
const router = express.Router();

const UserController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');
const {
  changePasswordRateLimiter,
  signedUploadUrlRateLimiter,
} = require('../middleware/rateLimiters');

// Totes les rutes requereixen autenticació; aplicat a nivell de router per
// no haver-ho de repetir.
router.use(authMiddleware);

router.put('/password', changePasswordRateLimiter, UserController.changePassword);
router.get('/profile', UserController.getProfile);
router.put('/profile', UserController.updateProfile);
router.delete('/account', UserController.deleteAccount);

// Foto de perfil: el client demana signed URL, puja directe a GCS, després
// confirma el path. El rate limiter també s'aplica a PUT i DELETE perquè
// cada operació toca BD i fa operacions a GCS.
router.post(
  '/profile-photo/signed-upload-url',
  signedUploadUrlRateLimiter,
  UserController.createProfilePhotoUploadUrl
);
router.put('/profile-photo', signedUploadUrlRateLimiter, UserController.setProfilePhoto);
router.delete('/profile-photo', signedUploadUrlRateLimiter, UserController.deleteProfilePhoto);

module.exports = router;
