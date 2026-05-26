const AuthService = require('../services/authService');
const UserModel = require('../models/userModel');

// Aquesta expressió valida el format bàsic del correu electrònic.
// Evita entrades clarament incorrectes abans de continuar amb el registre o l’inici de sessió.
const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const MIN_EMAIL_LENGTH = 5;

// Aquestes constants defineixen els límits principals dels camps d’usuari.
// Ajuden a protegir el sistema i mantenen la coherència amb les dades acceptades per l’aplicació.
const MAX_FIRST_NAME_LENGTH = 30;
const MAX_LAST_NAME_LENGTH = 30;
const MAX_EMAIL_LENGTH = 255;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

// Aquest mètode crea un error de validació amb codi 400.
// S’utilitza quan falten dades o quan el format rebut no és correcte.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest controlador gestiona les peticions relacionades amb l’autenticació i el perfil d’usuari.
// Valida les dades bàsiques, delega la lògica al servei corresponent i retorna la resposta HTTP.
const AuthController = {

  // Aquest mètode gestiona el registre d’un nou usuari.
  // Comprova les dades necessàries i crea el compte si la informació és vàlida.
  async register(req, res, next) {
    try {
      const { firstName, lastName, email, password } = req.body || {};
      if (!firstName || !lastName || !email || !password) {
        throw badRequest('Missing required fields: firstName, lastName, email, password');
      }

      // Aquestes comprovacions eviten guardar dades incompletes o massa llargues.
      // També redueixen el risc de peticions que puguin afectar el rendiment del servidor.
      if (firstName.length > MAX_FIRST_NAME_LENGTH) {
        throw badRequest(`First name must be at most ${MAX_FIRST_NAME_LENGTH} characters long`);
      }
      if (lastName.length > MAX_LAST_NAME_LENGTH) {
        throw badRequest(`Last name must be at most ${MAX_LAST_NAME_LENGTH} characters long`);
      }
      if (email.length < MIN_EMAIL_LENGTH) {
        throw badRequest(`Email must be at least ${MIN_EMAIL_LENGTH} characters long`);
      }
      if (email.length > MAX_EMAIL_LENGTH) {
        throw badRequest(`Email must be at most ${MAX_EMAIL_LENGTH} characters long`);
      }
      if (!EMAIL_REGEX.test(email)) {
        throw badRequest('Invalid email format');
      }
      if (password.length < MIN_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }

      // Aquest límit protegeix el procés de xifrat de contrasenyes.
      // Evita que una entrada excessivament gran pugui sobrecarregar el servidor.
      if (password.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const { id } = await AuthService.register({ firstName, lastName, email, password });
      res.status(201).json({ message: 'User created', userId: id });
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode gestiona l’inici de sessió.
  // Comprova que s’hagin enviat les credencials i delega la validació al servei.
  async login(req, res, next) {
    try {
      const { email, password } = req.body || {};
      if (!email || !password) {
        throw badRequest('Missing required fields: email, password');
      }

      const result = await AuthService.login({ email, password });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode inicia el procés de recuperació de contrasenya.
  // Utilitza el correu de l’usuari per generar el flux de restabliment.
  async requestPasswordReset(req, res, next) {
    try {
      const { email } = req.body || {};
      if (!email) {
        throw badRequest('Missing required field: email');
      }

      const result = await AuthService.requestPasswordReset(email);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode aplica el canvi de contrasenya mitjançant un token de recuperació.
  // Valida la nova contrasenya abans de delegar l’actualització al servei.
  async resetPassword(req, res, next) {
    try {
      const { token, newPassword } = req.body || {};

      if (!token || !newPassword) {
        throw badRequest('Missing required fields: token, newPassword');
      }
      if (newPassword.length < MIN_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }

      // Aquest límit evita que el procés de recuperació pugui rebre contrasenyes excessivament llargues.
      if (newPassword.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const result = await AuthService.resetPassword({ token, newPassword });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Aquest mètode retorna el perfil de l’usuari autenticat.
  // L’identificador prové del middleware d’autenticació i permet recuperar només les seves dades.
  async getProfile(req, res, next) {
    try {
      const userId = req.userId; // Valor establert pel middleware d'autenticació
      const user = await UserModel.findById(userId);

      if (!user) {
        const error = new Error('User not found');
        error.statusCode = 404;
        throw error;
      }

      // La resposta exclou la contrasenya per protegir la informació sensible de l’usuari.
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AuthController;