const UserService = require('../services/userService');
const Validation = require('../utils/validation');

// Aquestes constants defineixen els límits dels camps editables del perfil.
// Permeten validar les dades abans d’enviar-les al servei i mantenir coherència amb el registre.
const MAX_FIRST_NAME_LENGTH = 30;
const MAX_LAST_NAME_LENGTH = 30;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;


// Aquest controlador gestiona les peticions relacionades amb el perfil de l’usuari.
// Valida les dades bàsiques, delega la lògica al servei corresponent i retorna la resposta HTTP.
const UserController = {

  // Retorna el perfil de l’usuari autenticat.
  // L’identificador prové del middleware d’autenticació i permet recuperar només les seves dades.
  async getProfile(req, res, next) {
    try {
      const userId = req.userId;
      const user = await UserService.getProfile(userId);
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  },

  // Actualitza el nom i el cognom de l’usuari autenticat.
  // Les comprovacions eviten guardar dades incompletes o massa llargues.
  async updateProfile(req, res, next) {
    try {
      const userId = req.userId;
      const { firstName, lastName } = req.body || {};

      if (!firstName || !lastName) {
        throw Validation.badRequest('Missing required fields: firstName, lastName');
      }
      if (firstName.length > MAX_FIRST_NAME_LENGTH) {
        throw Validation.badRequest(`First name must be at most ${MAX_FIRST_NAME_LENGTH} characters long`);
      }
      if (lastName.length > MAX_LAST_NAME_LENGTH) {
        throw Validation.badRequest(`Last name must be at most ${MAX_LAST_NAME_LENGTH} characters long`);
      }

      const updatedUser = await UserService.updateProfile(userId, { firstName, lastName });
      res.status(200).json(updatedUser);
    } catch (error) {
      next(error);
    }
  },

  // Canvia la contrasenya de l’usuari autenticat.
  // Valida la contrasenya actual i els límits de la nova abans de delegar l’actualització al servei.
  async changePassword(req, res, next) {
    try {
      const userId = req.userId;
      const { currentPassword, newPassword } = req.body || {};

      if (!currentPassword || !newPassword) {
        throw Validation.badRequest('Missing required fields: currentPassword, newPassword');
      }
      if (newPassword.length < MIN_PASSWORD_LENGTH) {
        throw Validation.badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }
      if (newPassword.length > MAX_PASSWORD_LENGTH) {
        throw Validation.badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const result = await UserService.changePassword(userId, { currentPassword, newPassword });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Elimina el compte de l’usuari autenticat.
  // La contrasenya confirma que l’acció la fa realment el propietari del compte.
  async deleteAccount(req, res, next) {
    try {
      const userId = req.userId;
      const { password } = req.body || {};

      if (!password) {
        throw Validation.badRequest('Missing required field: password');
      }

      const result = await UserService.deleteAccount(userId, { password });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Genera una URL temporal per pujar la foto de perfil.
  // Això permet que el frontend enviï la imatge directament al sistema d’emmagatzematge.
  async createProfilePhotoUploadUrl(req, res, next) {
    try {
      const { mimeType } = req.body || {};
      const result = await UserService.generateProfilePhotoUploadUrl(req.userId, { mimeType });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Confirma la foto de perfil pujada per l’usuari.
  // El servei guarda la ruta de la imatge i retorna el perfil actualitzat.
  async setProfilePhoto(req, res, next) {
    try {
      const { storagePath } = req.body || {};
      const updated = await UserService.setProfilePhoto(req.userId, { storagePath });
      res.status(200).json(updated);
    } catch (error) {
      next(error);
    }
  },

  // Elimina la foto de perfil de l’usuari autenticat.
  // Retorna el perfil actualitzat perquè el frontend pugui mostrar el canvi immediatament.
  async deleteProfilePhoto(req, res, next) {
    try {
      const updated = await UserService.removeProfilePhoto(req.userId);
      res.status(200).json(updated);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = UserController;