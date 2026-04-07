const AuthService = require('../services/authService');

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
      const result = await AuthService.login(req.body);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AuthController;