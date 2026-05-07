const pool = require('../config/db');

// Accés a password_reset_tokens.
const PasswordResetModel = {

  async create({ userId, token, expiresAt }) {
    const sql = `
      INSERT INTO password_reset_tokens (user_id, token, expires_at)
      VALUES (?, ?, ?)
    `;

    const [result] = await pool.execute(sql, [userId, token, expiresAt]);
    return this.findById(result.insertId);
  },

  async findById(id) {
    const sql = `
      SELECT id, user_id, token, expires_at, is_used, created_at
      FROM password_reset_tokens
      WHERE id = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [id]);
    return rows[0] || null;
  },

  async findByToken(token) {
    const sql = `
      SELECT id, user_id, token, expires_at, is_used, created_at
      FROM password_reset_tokens
      WHERE token = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [token]);
    return rows[0] || null;
  },

  // Marca el token com a utilitzat per evitar la reutilització.
  async markAsUsed(id) {
    const sql = `
      UPDATE password_reset_tokens
      SET is_used = 1
      WHERE id = ?
    `;

    await pool.execute(sql, [id]);
    return this.findById(id);
  },

  // Esborra els tokens caducats o ja utilitzats. Cridat periòdicament des
  // del server per mantenir la taula neta.
  async deleteExpired() {
    const sql = `
      DELETE FROM password_reset_tokens
      WHERE expires_at < NOW() OR is_used = 1
    `;

    const [result] = await pool.execute(sql);
    return result.affectedRows;
  },

  // Esborra tots els tokens d'un usuari (per invalidar processos anteriors
  // quan se'n genera un de nou).
  async deleteByUserId(userId) {
    const sql = `
      DELETE FROM password_reset_tokens
      WHERE user_id = ?
    `;

    const [result] = await pool.execute(sql, [userId]);
    return result.affectedRows;
  },
};

module.exports = PasswordResetModel;
