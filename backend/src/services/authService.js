const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const PasswordResetModel = require('../models/passwordResetModel');
const EmailService = require('./emailService');

const SALT_ROUNDS = 10;
const RESET_TOKEN_EXPIRY_HOURS = 3;

// Hash del token de recuperació per guardar-lo a la BD. Així no es conserva
// el valor en text visible i tot i així es pot validar més tard.
function hashResetToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// Normalitza el correu (trim + lowercase) abans de qualsevol consulta o
// inserció. Així "Marco@Gmail.com" i "marco@gmail.com" identifiquen sempre
// el mateix usuari i s'eviten registres duplicats.
function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

// Lògica d'autenticació i recuperació de contrasenya.
const AuthService = {

  async hashPassword(password) {
    return bcrypt.hash(password, SALT_ROUNDS);
  },

  async comparePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  },

  // Genera el JWT d'accés per a un usuari autenticat.
  generateToken(userId) {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }
    const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
    return jwt.sign({ userId }, secret, { expiresIn });
  },

  // Registra un nou usuari. Trim de noms i normalització de correu.
  async register({ firstName, lastName, email, password }) {
    const trimmedFirstName = firstName.trim();
    const trimmedLastName = lastName.trim();

    const normalizedEmail = normalizeEmail(email);
    const existing = await UserModel.findByEmail(normalizedEmail);

    if (existing) {
      const error = new Error('Email is already registered');
      error.statusCode = 409;
      throw error;
    }

    const hashedPassword = await this.hashPassword(password);
    const user = await UserModel.create({
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
      email: normalizedEmail,
      password: hashedPassword,
    });

    return { id: user.id };
  },

  // Inici de sessió. Normalitza el correu perquè funcioni amb majúscules o
  // espais inadvertits.
  async login({ email, password }) {
    const user = await UserModel.findByEmail(normalizeEmail(email));

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

    const token = this.generateToken(user.id);

    return {
      message: 'Login successful',
      token,
      userId: user.id,
    };
  },

  // Inicia el procés de recuperació. La resposta sempre és la mateixa per
  // no filtrar si un correu existeix (anti-enumeration).
  async requestPasswordReset(email) {
    const genericResponse = {
      message: 'If the email exists, a reset token has been generated',
    };

    const user = await UserModel.findByEmail(normalizeEmail(email));
    if (!user) {
      return genericResponse;
    }

    // S'eliminen tokens anteriors per no tenir-ne més d'un actiu alhora.
    await PasswordResetModel.deleteByUserId(user.id);

    const token = crypto.randomBytes(32).toString('hex');
    const tokenHash = hashResetToken(token);

    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + RESET_TOKEN_EXPIRY_HOURS);

    await PasswordResetModel.create({
      userId: user.id,
      token: tokenHash,
      expiresAt,
    });

    // Si l'enviament falla, es loga però no es propaga: la resposta ha de ser
    // sempre la mateixa per no filtrar via error si el correu existeix.
    try {
      await EmailService.sendPasswordReset({
        to: user.email,
        token,
        expiryHours: RESET_TOKEN_EXPIRY_HOURS,
      });
    } catch (error) {
      console.error('Error sending password reset email:', error);
    }

    // El token NO es loga mai, ni en dev: deixar-lo a logs significa que
    // qualsevol amb accés a la consola pot suplantar l'usuari fins que caduqui.
    // Per provar el flux en local cal obrir el correu o consultar la taula
    // password_reset_tokens directament a la BD.
    return genericResponse;
    },

  // Aplica el canvi de contrasenya amb el token de recuperació.
  async resetPassword({ token, newPassword }) {
    const tokenHash = hashResetToken(token);
    const resetToken = await PasswordResetModel.findByToken(tokenHash);

    if (!resetToken) {
      const error = new Error('Invalid or expired reset token');
      error.statusCode = 400;
      throw error;
    }

    if (resetToken.is_used) {
      const error = new Error('Reset token has already been used');
      error.statusCode = 400;
      throw error;
    }

    const now = new Date();
    const expiresAt = new Date(resetToken.expires_at);

    if (now > expiresAt) {
      const error = new Error('Reset token has expired');
      error.statusCode = 400;
      throw error;
    }

    const hashedPassword = await this.hashPassword(newPassword);
    await UserModel.updatePassword(resetToken.user_id, hashedPassword);
    await PasswordResetModel.markAsUsed(resetToken.id);

    return { message: 'Password has been reset successfully' };

  },
};

module.exports = AuthService;
