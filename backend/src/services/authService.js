const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const PasswordResetModel = require('../models/passwordResetModel');

// Nombre de vegades que bcrypt processa la contrasenya per generar el hash.
// 10 és l'estàndard de la indústria — uns 100ms en un servidor modern.
const SALT_ROUNDS = 10;
const RESET_TOKEN_EXPIRY_HOURS = 1;

// Servei d'autenticació — conté tota la lògica de registre, login i gestió de contrasenyes.
// Cap altra capa ha de saber com funciona bcrypt o JWT.
const AuthService = {

  // Rep la contrasenya en text pla i retorna el hash segur
  // que es guardarà a la base de dades.
  async hashPassword(password) {
    return bcrypt.hash(password, SALT_ROUNDS);
  },

  // Compara la contrasenya en text pla (del formulari de login)
  // amb el hash guardat a la base de dades.
  // Retorna true si coincideixen, false si no.
  async comparePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  },

  // Genera un token JWT per un usuari autenticat
  generateToken(userId) {
    const secret = process.env.JWT_SECRET;

    // Comprova que la clau secreta està definida
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }
    const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
    return jwt.sign({ userId }, secret, { expiresIn });
  },

  // Orquestra el procés complet de registre
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

  // Orquestra el procés de login
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

    // Genera un token JWT per l'usuari autenticat
    const token = this.generateToken(user.id);

    return {
      message: 'Login successful',
      token,
      userId: user.id,
    };
  },

  async requestPasswordReset(email) {
    const genericResponse = {
      message: 'If the email exists, a reset token has been generated',
    };

    const user = await UserModel.findByEmail(email);
    if (!user) {
      return genericResponse;
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

    // En producció el token s'envia per correu i MAI a la resposta HTTP
    // (si es retornés, un atacant podria enumerar emails vàlids).
    // En desenvolupament local el retornem per facilitar les proves manuals.
    if (process.env.NODE_ENV !== 'production') {
      return { ...genericResponse, token };
    }
    return genericResponse;
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
    await UserModel.updatePassword(resetToken.user_id, hashedPassword);
    await PasswordResetModel.markAsUsed(resetToken.id);

    return { message: 'Password has been reset successfully' };

  }, 
};

module.exports = AuthService;