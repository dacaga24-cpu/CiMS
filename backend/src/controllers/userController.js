const UserService = require('../services/userService');
const Validation = require('../utils/validation');

// Aquestes constants defineixen els límits de longitud acceptats als camps editables
// del perfil. Coincideixen amb els tipus definits a la base de dades i amb els
// mateixos valors que s'utilitzen durant el registre per mantenir coherència.
const MAX_FIRST_NAME_LENGTH = 30;
const MAX_LAST_NAME_LENGTH = 30;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;


// Aquest controlador gestiona les peticions relacionades amb el perfil de l'usuari.
// La seva funció és rebre les dades de la petició, validar les més bàsiques,
// delegar la feina al servei corresponent i enviar la resposta HTTP.
const UserController = {

  // Aquest mètode retorna el perfil de l'usuari autenticat.
  // L'identificador arriba preparat pel middleware d'autenticació
  // i es trasllada directament al servei sense cap manipulació addicional.
  async getProfile(req, res, next) {
    try {
      const userId = req.userId;
      const user = await UserService.getProfile(userId);
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode actualitza el nom i el cognom de l'usuari autenticat.
  // Comprova que els camps obligatoris arribin i que la seva longitud
  // no superi els límits definits per la base de dades.
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

  // Genera una signed URL perquè el frontend pugui pujar la foto de perfil
  // directament al bucket de GCS sense passar pel backend.
  async createProfilePhotoUploadUrl(req, res, next) {
    try {
      const { mimeType } = req.body || {};
      const result = await UserService.generateProfilePhotoUploadUrl(req.userId, { mimeType });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Confirma una pujada de foto de perfil un cop el client l'ha completada
  // contra GCS. Retorna el perfil actualitzat amb la signed URL ja
  // disponible per visualitzar.
  async setProfilePhoto(req, res, next) {
    try {
      const { storagePath } = req.body || {};
      const updated = await UserService.setProfilePhoto(req.userId, { storagePath });
      res.status(200).json(updated);
    } catch (error) {
      next(error);
    }
  },

  // Esborra la foto de perfil. Idempotent: respon 200 amb el perfil tal
  // com queda fins i tot si l'usuari no en tenia cap.
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