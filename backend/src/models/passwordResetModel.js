const pool = require('../config/db');

// Aquest model gestiona els tokens de recuperació de contrasenya.
// Permet crear-los, consultar-los, marcar-los com a utilitzats i eliminar els que ja no són vàlids.
const PasswordResetModel = {

  // Crea un nou token de recuperació per a un usuari.
  // La data de caducitat permet limitar durant quant temps es pot utilitzar.
  async create({ userId, token, expiresAt }) {
    const sql = `
      INSERT INTO password_reset_tokens (user_id, token, expires_at)
      VALUES (?, ?, ?)
    `;

    const [result] = await pool.execute(sql, [userId, token, expiresAt]);
    return this.findById(result.insertId);
  },

  // Busca un token de recuperació pel seu identificador intern.
  // Retorna el registre si existeix o null si no s’ha trobat.
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

  // Busca un registre a partir del token rebut.
  // Aquesta consulta permet validar si un enllaç de recuperació existeix i encara es pot utilitzar.
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

  // Marca un token com a utilitzat.
  // Això evita que el mateix procés de recuperació es pugui repetir més d’una vegada.
  async markAsUsed(id) {
    const sql = `
      UPDATE password_reset_tokens
      SET is_used = 1
      WHERE id = ?
    `;

    await pool.execute(sql, [id]);
    return this.findById(id);
  },

  // Elimina els tokens caducats o ja utilitzats.
  // Aquesta neteja evita acumular registres que ja no tenen valor funcional.
  async deleteExpired() {
    const sql = `
      DELETE FROM password_reset_tokens
      WHERE expires_at < NOW() OR is_used = 1
    `;

    const [result] = await pool.execute(sql);
    return result.affectedRows;
  },

  // Elimina tots els tokens de recuperació d’un usuari.
  // Serveix per invalidar processos anteriors quan cal garantir un únic flux actiu.
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