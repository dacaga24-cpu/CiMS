const AuthService = require('../services/authService');
const UserModel = require('../models/userModel');

// El controller és la capa que gestiona la comunicació HTTP.
// Extreu les dades de la petició, delega la feina al service
// i envia la resposta HTTP. Mai conté lògica de negoci ni SQL.
const AuthController = {

  // Extreu els camps del body, crida al service i retorna la resposta HTTP.
  async register(req, res, next) {
    try {
      const { firstName, lastName, email, password } = req.body;
      const user = await AuthService.register({ firstName, lastName, email, password });
      res.status(201).json({ message: 'User created', userId: user.id });
    } catch (error) {
      next(error);
    }
  },

  // Extreu email i contrasenya del body, els passa al service.
  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const result = await AuthService.login({ email, password });
      res.status(200).json(result);
    } catch (error) {
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

      // No retornar la contrasenya
      const { password, ...userWithoutPassword } = user;

      res.status(200).json(userWithoutPassword);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AuthController;