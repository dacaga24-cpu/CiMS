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
      const { email, password } = req.body;
      const result = await AuthService.login({ email, password });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  async requestPasswordReset(req, res, next) {
    try {
      const { email } = req.body;
      const result = await AuthService.requestPasswordReset(email);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  async resetPassword(req, res, next) {
    try {
      const { token, newPassword } = req.body;
      const result = await AuthService.resetPassword({ token, newPassword });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AuthController;