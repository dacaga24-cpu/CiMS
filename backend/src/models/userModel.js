const pool = require('../config/db');

const UserModel = {
  async create({ firstName, lastName, email, password }) {
    const sql = `
      INSERT INTO users (first_name, last_name, email, password)
      VALUES (?, ?, ?, ?)
    `;

    const [result] = await pool.execute(sql, [
      firstName,
      lastName,
      email,
      password,
    ]);

    return this.findById(result.insertId);
  },

  async findById(id) {
    const sql = `
      SELECT id, first_name, last_name, email, password, is_active, created_at, updated_at
      FROM users
      WHERE id = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [id]);
    return rows[0] || null;
  },

  async findByEmail(email) {
    const sql = `
      SELECT id, first_name, last_name, email, password, is_active, created_at, updated_at
      FROM users
      WHERE email = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [email]);
    return rows[0] || null;
  },
};

module.exports = UserModel;