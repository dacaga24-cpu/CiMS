const AuthService = require('../services/authService');
const UserModel = require('../models/userModel');

// Validació de format d'email com a primera barrera abans de tocar la BD.
// No pretén implementar RFC 5322 sencer (caldria una llibreria); cobreix els
// casos clarament invàlids (sense @, sense domini, caràcters prohibits).
const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const MIN_EMAIL_LENGTH = 5;

// Límits alineats amb els tipus de la BD per evitar errors d'inserció.
// MAX_PASSWORD_LENGTH protegeix bcrypt: hashejar contrasenyes molt llargues
// és lent per disseny i un vector d'atac de CPU.
const MAX_FIRST_NAME_LENGTH = 100;
const MAX_LAST_NAME_LENGTH = 150;
const MAX_EMAIL_LENGTH = 255;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

// Crea un error de validació amb codi 400.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Controlador d'autenticació i perfil. Valida l'entrada bàsica i delega al
// servei.
const AuthController = {

  // Registre d'un nou usuari.
  async register(req, res, next) {
    try {
      const { firstName, lastName, email, password } = req.body || {};
      if (!firstName || !lastName || !email || !password) {
        throw badRequest('Missing required fields: firstName, lastName, email, password');
      }

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
      if (password.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const { id } = await AuthService.register({ firstName, lastName, email, password });
      res.status(201).json({ message: 'User created', userId: id });
    } catch (error) {
      next(error);
    }
  },

  // Inici de sessió.
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

  // Inicia el flux de recuperació de contrasenya.
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

  // Aplica el canvi de contrasenya amb el token de recuperació. Es
  // reaprofiten els mateixos límits del registre per protegir bcrypt.
  async resetPassword(req, res, next) {
    try {
      const { token, newPassword } = req.body || {};

      if (!token || !newPassword) {
        throw badRequest('Missing required fields: token, newPassword');
      }
      if (newPassword.length < MIN_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters long`);
      }
      if (newPassword.length > MAX_PASSWORD_LENGTH) {
        throw badRequest(`Password must be at most ${MAX_PASSWORD_LENGTH} characters long`);
      }

      const result = await AuthService.resetPassword({ token, newPassword });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  // Retorna el perfil de l'usuari autenticat. req.userId el posa el
  // middleware d'autenticació.
  async getProfile(req, res, next) {
    try {
      const userId = req.userId;
      const user = await UserModel.findById(userId);

      if (!user) {
        const error = new Error('User not found');
        error.statusCode = 404;
        throw error;
      }

      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AuthController;
