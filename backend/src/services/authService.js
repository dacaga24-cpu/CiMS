const bcrypt = require('bcrypt');
const UserModel = require('../models/userModel');

const SALT_ROUNDS = 10;

const AuthService = {
  async hashPassword(password) {
    return await bcrypt.hash(password, SALT_ROUNDS);
  },

  async comparePassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  },

  async register({ firstName, lastName, email, password }) {
    const existing = await UserModel.findByEmail(email);

    if (existing) {
      const error = new Error('Email is already registered');
      error.statusCode = 409;
      throw error;
    }

    const hashedPassword = await this.hashPassword(password);
    const user = await UserModel.create({ firstName, lastName, email, password: hashedPassword });
    
    return { id: user.id };
  },


  async login({ email, password }) {
    const user = await UserModel.findByEmail(email);

    if (!user) {
      const error = new Error('Invalid credentials');
      error.statusCode = 401;
      throw error;
    }

    const isPasswordValid = await this.comparePassword(password, user.password);

    if (!isPasswordValid) {
      const error = new Error('Invalid credentials');
      error.statusCode = 401;
      throw error;
    }

    return {
      message: 'Login successful',
      userId: user.id,
    };
  },
};

module.exports = AuthService;