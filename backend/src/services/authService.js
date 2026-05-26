const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const PasswordResetModel = require('../models/passwordResetModel');
const EmailService = require('./emailService');

// Aquestes constants defineixen la seguretat bàsica de l’autenticació.
// Controlen el xifrat de contrasenyes i la durada dels tokens de recuperació.
const SALT_ROUNDS = 10;
const RESET_TOKEN_EXPIRY_HOURS = 3;

// Aquest mètode protegeix el token de recuperació abans de guardar-lo.
// Permet validar-lo després sense conservar el valor original en text visible.
function hashResetToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// Aquest mètode normalitza el correu electrònic abans d’utilitzar-lo.
// Evita duplicats i permet identificar el mateix compte encara que s’escrigui amb majúscules o espais.
function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

// Aquest servei centralitza la lògica d’autenticació.
// Gestiona registre, inici de sessió, tokens d’accés i recuperació de contrasenya.
const AuthService = {

  // Converteix una contrasenya en una versió segura abans de guardar-la.
  // Això evita emmagatzemar contrasenyes visibles a la base de dades.
  async hashPassword(password) {
    return bcrypt.hash(password, SALT_ROUNDS);
  },

  // Compara una contrasenya introduïda amb la versió guardada.
  // Serveix per validar les credencials durant l’inici de sessió.
  async comparePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  },

  // Genera el token d’accés d’un usuari autenticat.
  // Aquest token permet identificar la sessió en les rutes protegides.
  generateToken(userId) {
    const secret = process.env.JWT_SECRET;

    // Aquesta comprovació assegura que el servidor pot signar tokens correctament.
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }
    const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
    return jwt.sign({ userId }, secret, { expiresIn });
  },

  // Registra un nou usuari al sistema.
  // Normalitza les dades, comprova si el correu ja existeix i guarda la contrasenya protegida.
  async register({ firstName, lastName, email, password }) {
    // Els noms es guarden sense espais inicials ni finals.
    // Això evita variants visuals del mateix nom dins de la base de dades.
    const trimmedFirstName = firstName.trim();
    const trimmedLastName = lastName.trim();

    // El correu es normalitza abans de consultar o crear l’usuari.
    // Això manté un criteri únic per identificar comptes.
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

  // Gestiona l’inici de sessió d’un usuari.
  // Valida les credencials i retorna un token d’accés si són correctes.
  async login({ email, password }) {
    // El correu es normalitza perquè l’accés sigui consistent encara que l’usuari l’escrigui amb variacions.
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

    // Un cop validat l’usuari, es crea el token que identifica la seva sessió.
    const token = this.generateToken(user.id);

    return {
      message: 'Login successful',
      token,
      userId: user.id,
    };
  },

  // Inicia el procés de recuperació de contrasenya.
  // Si el correu existeix, crea un token temporal i envia l’enllaç de recuperació.
  async requestPasswordReset(email) {
    const genericResponse = {
      message: 'If the email exists, a reset token has been generated',
    };

    // El correu es normalitza per trobar el compte encara que s’hagi escrit amb variacions.
    const user = await UserModel.findByEmail(normalizeEmail(email));
    if (!user) {
      return genericResponse;
    }

    // S’eliminen tokens anteriors per mantenir un únic procés de recuperació actiu.
    await PasswordResetModel.deleteByUserId(user.id);

    // Aquest token temporal autoritza el canvi de contrasenya.
    const token = crypto.randomBytes(32).toString('hex');

    // Només es guarda una versió protegida del token a la base de dades.
    const tokenHash = hashResetToken(token);

    // Aquest bloc calcula fins quan serà vàlid el token de recuperació.
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + RESET_TOKEN_EXPIRY_HOURS);

    // Es desa el token protegit juntament amb la seva caducitat.
    await PasswordResetModel.create({
      userId: user.id,
      token: tokenHash,
      expiresAt,
    });

    // S’envia el correu de recuperació mantenint una resposta genèrica al client.
    // Això evita revelar si un correu està registrat al sistema.
    try {
      await EmailService.sendPasswordReset({
        to: user.email,
        token,
        expiryHours: RESET_TOKEN_EXPIRY_HOURS,
      });
    } catch (error) {
      console.error('Error sending password reset email:', error);
    }

    // El token original no es registra mai als logs per protegir el compte de l’usuari.
    return genericResponse;
    },

  // Aplica el canvi de contrasenya a partir d’un token de recuperació.
  // Valida el token, comprova que no estigui caducat i desa la nova contrasenya.
  async resetPassword({ token, newPassword }) {
    // El token rebut es protegeix per comparar-lo amb el valor guardat.
    const tokenHash = hashResetToken(token);
    const resetToken = await PasswordResetModel.findByToken(tokenHash);

    if (!resetToken) {
      const error = new Error('Invalid or expired reset token');
      error.statusCode = 400;
      throw error;
    }

    // Aquesta comprovació evita reutilitzar un token ja consumit.
    if (resetToken.is_used) {
      const error = new Error('Reset token has already been used');
      error.statusCode = 400;
      throw error;
    }

    // Aquesta comprovació valida que el token encara estigui dins del seu temps d’ús.
    const now = new Date();
    const expiresAt = new Date(resetToken.expires_at);

    if (now > expiresAt) {
      const error = new Error('Reset token has expired');
      error.statusCode = 400;
      throw error;
    }

    // Si el token és vàlid, es desa la nova contrasenya i es tanca el procés de recuperació.
    const hashedPassword = await this.hashPassword(newPassword);
    await UserModel.updatePassword(resetToken.user_id, hashedPassword);
    await PasswordResetModel.markAsUsed(resetToken.id);

    return { message: 'Password has been reset successfully' };

  },
};

module.exports = AuthService;