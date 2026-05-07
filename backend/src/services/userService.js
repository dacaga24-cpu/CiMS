const UserModel = require('../models/userModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const { badRequest } = require('../utils/validation');
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 10;

// Lògica de negoci del perfil d'usuari. La foto de perfil reutilitza el
// patró de signed URL directa a GCS de les fotos d'ascens, però amb el
// namespace `profile-photos` per separar-les a nivell de bucket i validació.

// Esborra un blob sense aturar el flux si falla. S'usa quan se substitueix o
// s'elimina la foto de perfil: si GCS té un problema transitori, el path a
// la BD ja està actualitzat i un orfe es netejarà amb un job posterior.
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

// Construeix la representació pública del perfil. Genera la signed URL aquí
// (no al model) perquè és asíncrona, i omet el path cru perquè el client
// no l'ha de necessitar mai i així no filtrem l'esquema intern del bucket.
// Si la signatura falla, profilePhotoUrl queda a null i les dades bàsiques
// segueixen arribant al client.
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

  // Recupera el perfil amb la signed URL ja generada perquè el client no
  // hagi de fer una segona crida.
  async getProfile(userId) {
    const user = await UserModel.findById(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    return composeProfileResponse(user);
  },

  // Actualitza nom i cognom. Es netegen d'espais superflus per no guardar
  // variants idènticament visuals però diferents a nivell de text.
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

  async changePassword(userId, { currentPassword, newPassword }) {
    const user = await UserModel.findByIdWithPassword(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    // Es verifica la contrasenya actual abans del canvi per confirmar que
    // qui fa la petició és el titular del compte.
    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      const error = new Error('Current password is incorrect');
      error.statusCode = 401;
      throw error;
    }

    const hashedPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(userId, hashedPassword);

    return { message: 'Password changed successfully' };
  },

  // Desactiva el compte (soft delete) prèvia confirmació de la contrasenya.
  // Per decisió de producte, els blobs (foto perfil, fotos d'ascens) NO
  // s'esborren: les dades es conserven per si l'usuari reactiva el compte.
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
      error.statusCode = 401;
      throw error;
    }

    await UserModel.deactivateAccount(userId);
    return { message: 'Account deleted successfully' };
  },

  // Genera una signed URL de pujada de foto de perfil amb namespace
  // `profile-photos` perquè quedi separada de les fotos d'ascens.
  async generateProfilePhotoUploadUrl(userId, { mimeType } = {}) {
    if (!mimeType || typeof mimeType !== 'string') {
      throw badRequest('Missing required field: mimeType');
    }
    return StorageService.generateSignedUploadUrl(userId, mimeType, 'profile-photos');
  },

  // Confirma una pujada de foto de perfil. Valida el shape del path i que
  // el blob existeix realment. La foto anterior s'esborra del bucket sense
  // bloquejar (safeDeleteProfilePhotoBlob).
  //
  // Race condition coneguda: dos PUTs concurrents poden interleave i deixar
  // la BD apuntant a un blob que el rival ja ha esborrat. Mitigació actual:
  // rate limiter + una sola sessió per usuari. Si calgués més garantia,
  // UPDATE condicional o SELECT ... FOR UPDATE.
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

    // Reaprofitem la fila ja llegida per evitar un segon findById.
    return composeProfileResponse({ ...previous, profile_photo_path: storagePath });
  },

  // Esborra la foto de perfil. Idempotent: si l'usuari no en tenia, no fa
  // res; si en tenia, posa el camp a NULL i intenta esborrar el blob.
  async removeProfilePhoto(userId) {
    const user = await UserModel.findById(userId);
    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }
    const previousPath = user.profile_photo_path;

    // Camí ràpid quan no hi havia foto.
    if (!previousPath) {
      return composeProfileResponse(user);
    }

    await UserModel.updateProfilePhoto(userId, null);
    await safeDeleteProfilePhotoBlob(previousPath, { userId });

    return composeProfileResponse({ ...user, profile_photo_path: null });
  },
};

module.exports = UserService;
