const bcrypt = require('bcrypt');
const crypto = require('crypto');
const UserModel = require('../models/userModel');
const PasswordResetModel = require('../models/passwordResetModel');

const SALT_ROUNDS = 10;
const RESET_TOKEN_EXPIRY_HOURS = 1;

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

  async requestPasswordReset(email) {
    const user = await UserModel.findByEmail(email);

    if (!user) {
      // Per seguretat, no revelar si l'email existeix o no
      return {
        message: 'If the email exists, a reset token has been generated',
      };
    }

    // Eliminar tokens anteriors d'aquest usuari
    await PasswordResetModel.deleteByUserId(user.id);

    // Generar token aleatori segur
    const token = crypto.randomBytes(32).toString('hex');

    // Calcular data d'expiració
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + RESET_TOKEN_EXPIRY_HOURS);

    // Guardar el token
    await PasswordResetModel.create({
      userId: user.id,
      token,
      expiresAt,
    });

    return {
      message: 'If the email exists, a reset token has been generated',
      token, // En producció, això s'enviaria per email
    };
  },

  async resetPassword({ token, newPassword }) {
    const resetToken = await PasswordResetModel.findByToken(token);

    if (!resetToken) {
      const error = new Error('Invalid or expired reset token');
      error.statusCode = 400;
      throw error;
    }

    // Verificar si el token ja s'ha utilitzat
    if (resetToken.is_used) {
      const error = new Error('Reset token has already been used');
      error.statusCode = 400;
      throw error;
    }

    // Verificar si el token ha expirat
    const now = new Date();
    const expiresAt = new Date(resetToken.expires_at);

    if (now > expiresAt) {
      const error = new Error('Reset token has expired');
      error.statusCode = 400;
      throw error;
    }

    // Hash de la nova contrasenya
    const hashedPassword = await this.hashPassword(newPassword);

    // Actualitzar la contrasenya de l'usuari
    const sql = `
      UPDATE users
      SET password = ?
      WHERE id = ?
    `;

    const pool = require('../config/db');
    await pool.execute(sql, [hashedPassword, resetToken.user_id]);

    // Marcar el token com a utilitzat
    await PasswordResetModel.markAsUsed(resetToken.id);

    return {
      message: 'Password has been reset successfully',
    };
  },
};

module.exports = AuthService;