const AuthService = require('../services/authService');
const UserModel = require('../models/userModel');

const AuthController = {
  async register(req, res, next) {
    try {
      const { firstName, lastName, email, password } = req.body;
      const user = await AuthService.register({ firstName, lastName, email, password });
      res.status(201).json({ message: 'User created', userId: user.id });
    } catch (error) {
      next(error);
    }
  },

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