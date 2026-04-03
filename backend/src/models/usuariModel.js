const { pool } = require('../config/db');
const bcrypt = require('bcryptjs');

class UsuariModel {
  // Crear un nou usuari
  static async create({ username, email, password }) {
    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await pool.query(
      'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
      [username, email, hashedPassword]
    );

    return result.insertId;
  }

  // Trobar usuari per email
  static async findByEmail(email) {
    const [rows] = await pool.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
    return rows[0];
  }

  // Trobar usuari per ID
  static async findById(id) {
    const [rows] = await pool.query(
      'SELECT id, username, email, created_at FROM users WHERE id = ?',
      [id]
    );
    return rows[0];
  }

  // Trobar usuari per username
  static async findByUsername(username) {
    const [rows] = await pool.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );
    return rows[0];
  }

  // Verificar contrasenya
  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  // Obtenir tots els usuaris
  static async findAll() {
    const [rows] = await pool.query(
      'SELECT id, username, email, created_at FROM users'
    );
    return rows;
  }

  // Actualitzar usuari
  static async update(id, { username, email }) {
    const [result] = await pool.query(
      'UPDATE users SET username = ?, email = ? WHERE id = ?',
      [username, email, id]
    );
    return result.affectedRows > 0;
  }

  // Eliminar usuari
  static async delete(id) {
    const [result] = await pool.query(
      'DELETE FROM users WHERE id = ?',
      [id]
    );
    return result.affectedRows > 0;
  }
}

module.exports = UsuariModel;
