const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');

// Nombre de vegades que bcrypt processa la contrasenya per generar el hash.
// 10 és l'estàndard de la indústria — uns 100ms en un servidor modern.
const SALT_ROUNDS = 10;

// Servei d'autenticació — conté tota la lògica de registre, login i gestió de contrasenyes.
// Cap altra capa ha de saber com funciona bcrypt o JWT.
const AuthService = {

  // Rep la contrasenya en text pla i retorna el hash segur
  // que es guardarà a la base de dades.
  async hashPassword(password) {
    return await bcrypt.hash(password, SALT_ROUNDS);
  },

  // Compara la contrasenya en text pla (del formulari de login)
  // amb el hash guardat a la base de dades.
  // Retorna true si coincideixen, false si no.
  async comparePassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  },

  // Genera un token JWT per un usuari autenticat
  generateToken(userId) {
    const payload = { userId };
    const secret = process.env.JWT_SECRET;
    const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
    // Comprova que la clau secreta està definida
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }

    return jwt.sign(payload, secret, { expiresIn });
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
};

module.exports = AuthService;