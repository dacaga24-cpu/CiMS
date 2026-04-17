const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const PasswordResetModel = require('../models/passwordResetModel');

// Aquestes constants defineixen valors bàsics del sistema d’autenticació.
// Serveixen per fixar el nivell de protecció de les contrasenyes
// i el temps màxim de validesa dels tokens de recuperació.
const SALT_ROUNDS = 10;
const RESET_TOKEN_EXPIRY_HOURS = 1;

// Aquest mètode transforma el token de recuperació en una versió segura per guardar-la.
// És rellevant perquè permet validar després el token sense haver de conservar-lo en text visible.                                                                                                                        
function hashResetToken(token) {                                                                                                                                                            
  return crypto.createHash('sha256').update(token).digest('hex');                                                                                                                           
}     

// Aquest servei centralitza tota la lògica d’autenticació i recuperació de contrasenya.
// Aquí es resolen processos com el registre, el login, la generació de tokens
// i el restabliment segur de la contrasenya.
const AuthService = {

  // Aquest mètode converteix una contrasenya en una versió segura abans de guardar-la.
  // És important perquè evita emmagatzemar contrasenyes visibles a la base de dades.
  async hashPassword(password) {
    return bcrypt.hash(password, SALT_ROUNDS);
  },

  // Aquest mètode comprova si la contrasenya introduïda per l’usuari
  // coincideix amb la que hi ha guardada al sistema.
  async comparePassword(plainPassword, hashedPassword) {
    return bcrypt.compare(plainPassword, hashedPassword);
  },

  // Aquest mètode genera el token d’accés d’un usuari autenticat.
  // Aquest token és el que permet mantenir la sessió activa en les rutes protegides.
  generateToken(userId) {
    const secret = process.env.JWT_SECRET;

    // Aquest bloc comprova que el sistema disposi de la clau necessària
    // per poder generar tokens de manera correcta i segura.
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }
    const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
    return jwt.sign({ userId }, secret, { expiresIn });
  },

  // Aquest mètode gestiona el registre complet d’un nou usuari.
  // Primer comprova si el correu ja existeix, després prepara la contrasenya
  // i finalment crea el compte a la base de dades.
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

  // Aquest mètode gestiona l’inici de sessió.
  // Comprova que l’usuari existeixi, valida la contrasenya
  // i, si tot és correcte, retorna el token d’accés.
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

    // Un cop validat l’usuari, es crea el token
    // que es farà servir per identificar la seva sessió.
    const token = this.generateToken(user.id);

    return {
      message: 'Login successful',
      token,
      userId: user.id,
    };
  },

  // Aquest mètode inicia el procés de recuperació de contrasenya.
  // Si el correu existeix, genera un token temporal i el guarda de forma segura
  // perquè després es pugui validar el canvi de contrasenya.
  async requestPasswordReset(email) {
    const genericResponse = {
      message: 'If the email exists, a reset token has been generated',
    };

    const user = await UserModel.findByEmail(email);
    if (!user) {
      return genericResponse;
    }

    // Aquest pas elimina possibles tokens anteriors del mateix usuari
    // per evitar que hi hagi més d’un procés de recuperació actiu alhora.
    await PasswordResetModel.deleteByUserId(user.id);

    // Aquest token és el valor temporal que s’utilitzarà per autoritzar el canvi de contrasenya.
    const token = crypto.randomBytes(32).toString('hex');

    // A la base de dades només se’n guarda una versió protegida,
    // de manera que el valor original no queda exposat.
    const tokenHash = hashResetToken(token); 

    // Aquest bloc calcula fins quan serà vàlid el token de recuperació.
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + RESET_TOKEN_EXPIRY_HOURS);

    // Es guarda el token de manera segura juntament amb la seva caducitat.
    await PasswordResetModel.create({
      userId: user.id,
      token: tokenHash,
      expiresAt,
    });

    // En entorn local es retorna el token per facilitar les proves manuals.
    // En un entorn real, aquest valor s’hauria d’enviar per un canal extern com el correu.
    if (process.env.NODE_ENV !== 'production') {
      return { ...genericResponse, token };
    }
    return genericResponse;
    },

  // Aquest mètode aplica el canvi de contrasenya quan l’usuari arriba
  // amb un token de recuperació i una nova contrasenya.
  async resetPassword({ token, newPassword }) {
    // El token rebut es transforma per poder-lo comparar
    // amb la versió segura que hi ha guardada al sistema.                                                                                                                                              
    const tokenHash = hashResetToken(token);   
    const resetToken = await PasswordResetModel.findByToken(tokenHash);

    if (!resetToken) {
      const error = new Error('Invalid or expired reset token');
      error.statusCode = 400;
      throw error;
    }

    // Aquest bloc evita reutilitzar un token que ja s’hagi fet servir abans.
    if (resetToken.is_used) {
      const error = new Error('Reset token has already been used');
      error.statusCode = 400;
      throw error;
    }

    // Aquest bloc comprova si el temps de validesa del token ja ha caducat.
    const now = new Date();
    const expiresAt = new Date(resetToken.expires_at);

    if (now > expiresAt) {
      const error = new Error('Reset token has expired');
      error.statusCode = 400;
      throw error;
    }

    // Si totes les comprovacions són correctes, es guarda la nova contrasenya
    // i es marca el token com a utilitzat per tancar el procés de recuperació.
    const hashedPassword = await this.hashPassword(newPassword);
    await UserModel.updatePassword(resetToken.user_id, hashedPassword);
    await PasswordResetModel.markAsUsed(resetToken.id);

    return { message: 'Password has been reset successfully' };

  },
};

module.exports = AuthService;