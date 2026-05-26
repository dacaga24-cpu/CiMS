const UserModel = require('../models/userModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const { badRequest } = require('../utils/validation');
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 10;

// Aquest servei centralitza la lògica relacionada amb el perfil d’usuari.
// Gestiona dades personals, contrasenya, desactivació del compte i foto de perfil.

// Aquest helper intenta eliminar una foto de perfil del bucket.
// Si l’eliminació falla, l’error queda registrat sense bloquejar el flux principal.
async function safeDeleteProfilePhotoBlob(storagePath, context = {}) {
  if (!storagePath) {
    return;
  }
  try {
    await StorageService.deleteObject(storagePath);
  } catch (err) {
    console.error(
      `[profilePhoto] orphan blob (userId=${context.userId ?? 'unknown'} path=${storagePath}):`,
      err
    );
  }
}

// Aquest helper prepara la resposta pública del perfil.
// Afegeix una URL temporal per mostrar la foto sense exposar la ruta interna del bucket.
async function composeProfileResponse(user) {
  let profilePhotoUrl = null;
  if (user.profile_photo_path) {
    try {
      profilePhotoUrl = await StorageService.generateSignedDownloadUrl(user.profile_photo_path);
    } catch (err) {
      console.error(
        `[profilePhoto] sign download URL failed (userId=${user.id} path=${user.profile_photo_path}):`,
        err
      );
    }
  }

  const { profile_photo_path, ...rest } = user;
  return { ...rest, profilePhotoUrl };
}

const UserService = {

  // Retorna el perfil complet de l’usuari autenticat.
  // Inclou la URL temporal de la foto perquè el frontend la pugui mostrar directament.
  async getProfile(userId) {
    const user = await UserModel.findById(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    return composeProfileResponse(user);
  },

  // Actualitza el nom i el cognom de l’usuari autenticat.
  // Neteja espais innecessaris i retorna el perfil actualitzat.
  async updateProfile(userId, { firstName, lastName }) {
    const trimmedFirstName = firstName.trim();
    const trimmedLastName = lastName.trim();

    await UserModel.updateProfile(userId, {
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
    });

    const user = await UserModel.findById(userId);
    return composeProfileResponse(user);
  },

  // Canvia la contrasenya de l’usuari autenticat.
  // Comprova primer la contrasenya actual per confirmar que l’acció és legítima.
  async changePassword(userId, { currentPassword, newPassword }) {
    const user = await UserModel.findByIdWithPassword(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      const error = new Error('Current password is incorrect');
      error.statusCode = 400;
      throw error;
    }

    const hashedPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(userId, hashedPassword);

    return { message: 'Password changed successfully' };
  },

  // Desactiva el compte de l’usuari autenticat.
  // La contrasenya confirma que l’acció la fa el titular del compte.
  async deleteAccount(userId, { password }) {
    const user = await UserModel.findByIdWithPassword(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      const error = new Error('Password is incorrect');
      error.statusCode = 400;
      throw error;
    }

    await UserModel.deactivateAccount(userId);
    return { message: 'Account deleted successfully' };
  },

  // Genera una URL temporal per pujar la foto de perfil.
  // La imatge queda separada de les fotos d’ascensions dins del bucket.
  async generateProfilePhotoUploadUrl(userId, { mimeType } = {}) {
    if (!mimeType || typeof mimeType !== 'string') {
      throw badRequest('Missing required field: mimeType');
    }
    return StorageService.generateSignedUploadUrl(userId, mimeType, 'profile-photos');
  },

  // Confirma una foto de perfil ja pujada al bucket.
  // Valida que la ruta pertanyi a l’usuari, comprova que existeixi i actualitza el perfil.
  async setProfilePhoto(userId, { storagePath } = {}) {
    if (!storagePath || typeof storagePath !== 'string') {
      throw badRequest('Missing required field: storagePath');
    }
    const pattern = buildUserPathPattern(userId, 'profile-photos');
    if (!pattern.test(storagePath)) {
      throw badRequest(
        'Invalid storagePath: has an unexpected shape or does not belong to the user namespace'
      );
    }

    const exists = await StorageService.objectExists(storagePath);
    if (!exists) {
      throw badRequest(`Invalid storagePath: does not exist in storage (${storagePath})`);
    }

    const previous = await UserModel.findById(userId);
    if (!previous) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }
    const previousPath = previous.profile_photo_path;

    await UserModel.updateProfilePhoto(userId, storagePath);

    if (previousPath && previousPath !== storagePath) {
      await safeDeleteProfilePhotoBlob(previousPath, { userId });
    }

    // Es construeix la resposta amb el perfil ja carregat i la nova ruta de foto.
    // Això evita una segona consulta a la base de dades.
    return composeProfileResponse({ ...previous, profile_photo_path: storagePath });
  },

  // Elimina la foto de perfil de l’usuari.
  // Si no tenia cap foto, retorna el perfil sense fer canvis innecessaris.
  async removeProfilePhoto(userId) {
    const user = await UserModel.findById(userId);
    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }
    const previousPath = user.profile_photo_path;

    if (!previousPath) {
      return composeProfileResponse(user);
    }

    await UserModel.updateProfilePhoto(userId, null);
    await safeDeleteProfilePhotoBlob(previousPath, { userId });

    // Es retorna el perfil amb la foto eliminada sense tornar a consultar la base de dades.
    return composeProfileResponse({ ...user, profile_photo_path: null });
  },
};

module.exports = UserService;