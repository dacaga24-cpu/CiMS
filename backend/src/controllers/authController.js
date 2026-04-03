const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const UsuariModel = require('../models/usuariModel');

class AuthController {
  // Registrar nou usuari
  static async register(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { username, email, password } = req.body;

      // Verificar si l'usuari ja existeix
      const existingUser = await UsuariModel.findByEmail(email);
      if (existingUser) {
        return res.status(409).json({
          error: 'Aquest email ja està registrat'
        });
      }

      const existingUsername = await UsuariModel.findByUsername(username);
      if (existingUsername) {
        return res.status(409).json({
          error: 'Aquest nom d\'usuari ja està en ús'
        });
      }

      // Crear nou usuari
      const userId = await UsuariModel.create({ username, email, password });

      // Generar token JWT
      const token = jwt.sign(
        { id: userId, username, email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      res.status(201).json({
        message: 'Usuari creat correctament',
        user: { id: userId, username, email },
        token
      });
    } catch (error) {
      console.error('Error en registre:', error);
      res.status(500).json({
        error: 'Error en el registre',
        message: error.message
      });
    }
  }

  // Iniciar sessió
  static async login(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      // Buscar usuari
      const user = await UsuariModel.findByEmail(email);
      if (!user) {
        return res.status(401).json({
          error: 'Credencials incorrectes'
        });
      }

      // Verificar contrasenya
      const isValidPassword = await UsuariModel.verifyPassword(
        password,
        user.password_hash
      );

      if (!isValidPassword) {
        return res.status(401).json({
          error: 'Credencials incorrectes'
        });
      }

      // Generar token JWT
      const token = jwt.sign(
        { id: user.id, username: user.username, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      res.json({
        message: 'Inici de sessió correcte',
        user: {
          id: user.id,
          username: user.username,
          email: user.email
        },
        token
      });
    } catch (error) {
      console.error('Error en login:', error);
      res.status(500).json({
        error: 'Error en l\'inici de sessió',
        message: error.message
      });
    }
  }

  // Obtenir perfil de l'usuari actual
  static async getProfile(req, res) {
    try {
      const user = await UsuariModel.findById(req.user.id);

      if (!user) {
        return res.status(404).json({
          error: 'Usuari no trobat'
        });
      }

      res.json({ user });
    } catch (error) {
      console.error('Error obtenint perfil:', error);
      res.status(500).json({
        error: 'Error obtenint el perfil',
        message: error.message
      });
    }
  }

  // Verificar token (útil per a refresh)
  static async verifyToken(req, res) {
    res.json({
      valid: true,
      user: req.user
    });
  }
}

module.exports = AuthController;
