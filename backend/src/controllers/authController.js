const AuthService = require('../services/authService');
const UserModel = require('../models/userModel');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function badRequest(message) {                                                                                                                                                              
  const error = new Error(message);
  error.statusCode = 400;                                                                                                                                                                   
  return error;                                                 
}

// El controller és la capa que gestiona la comunicació HTTP.
// Extreu les dades de la petició, delega la feina al service
// i envia la resposta HTTP. Mai conté lògica de negoci ni SQL.
const AuthController = {

  // Extreu els camps del body, crida al service i retorna la resposta HTTP.
  async register(req, res, next) {
    try {
      const { firstName, lastName, email, password } = req.body || {};
      if (!firstName || !lastName || !email || !password) {
        throw badRequest('Missing required fields: firstName, lastName, email, password');                                                                                                  
      }                                                         
      if (!EMAIL_REGEX.test(email)) {
        throw badRequest('Invalid email format');                                                                                                                                           
      }
      if (password.length < 8) {                                                                                                                                                            
        throw badRequest('Password must be at least 8 characters long');
      }

      const { id } = await AuthService.register({ firstName, lastName, email, password });
      res.status(201).json({ message: 'User created', userId: id });
    } catch (error) {
      next(error);
    }
  },

  // Extreu email i contrasenya del body, els passa al service.
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

  async resetPassword(req, res, next) {
    try {
      const { token, newPassword } = req.body || {};                                                                                                                                        
                                                                  
        if (!token || !newPassword) {
          throw badRequest('Missing required fields: token, newPassword');
        }                                                                                                                                                                                     
        if (newPassword.length < 8) {
          throw badRequest('Password must be at least 8 characters long');                                                                                                                    
        };

      const result = await AuthService.resetPassword({ token, newPassword });
      res.status(200).json(result);
    }  catch (error) {
      next(error);
    }
  },

  // Endpoint per obtenir el perfil de l'usuari autenticat
  async getProfile(req, res, next) {
    try {
      const userId = req.userId; // Valor establert pel middleware d'autenticació
      const user = await UserModel.findById(userId);

      if (!user) {
        const error = new Error('User not found');
        error.statusCode = 404;
        throw error;
      }

      // findById ja retorna l'usuari sense el password, no cal filtrar-lo aquí.
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  }
};

module.exports = AuthController;