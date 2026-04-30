const UserService = require('../services/userService');

// Aquestes constants defineixen els límits de longitud acceptats als camps editables
// del perfil. Coincideixen amb els tipus definits a la base de dades i amb els
// mateixos valors que s'utilitzen durant el registre per mantenir coherència.
const MAX_FIRST_NAME_LENGTH = 100;
const MAX_LAST_NAME_LENGTH = 150;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

// Aquest mètode crea un error de validació amb codi 400.
// S'utilitza quan falten dades o quan el format rebut no és correcte.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

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
        throw badRequest('Missing required fields: firstName, lastName');
      }
      if (firstName.length > MAX_FIRST_NAME_LENGTH) {
        throw badRequest(`First name must be at most ${MAX_FIRST_NAME_LENGTH} characters long`);
      }
      if (lastName.length > MAX_LAST_NAME_LENGTH) {
        throw badRequest(`Last name must be at most ${MAX_LAST_NAME_LENGTH} characters long`);
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
        throw badRequest('Missing required fields: currentPassword, newPassword');
      }
      if (newPassword.length < MIN_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }
      if (newPassword.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const result = await UserService.changePassword(userId, { currentPassword, newPassword });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = UserController;