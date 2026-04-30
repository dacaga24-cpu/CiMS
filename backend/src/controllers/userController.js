const UserService = require('../services/userService');

// Aquestes constants defineixen els límits de longitud acceptats als camps editables
// del perfil. Coincideixen amb els tipus definits a la base de dades i amb els
// mateixos valors que s'utilitzen durant el registre per mantenir coherència.
const MAX_FIRST_NAME_LENGTH = 100;
const MAX_LAST_NAME_LENGTH = 150;

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
};

module.exports = UserController;