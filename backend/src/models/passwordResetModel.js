const pool = require('../config/db');

// Aquest model gestiona els tokens utilitzats per recuperar la contrasenya.
// La seva funció és guardar-los, consultar-los, marcar-los com a utilitzats
// i eliminar els que ja no són vàlids.
const PasswordResetModel = {

  // Aquest mètode crea un nou registre de recuperació de contrasenya.
  // Rep l’identificador de l’usuari, el token i la seva data de caducitat,
  // i retorna el registre acabat de crear.
  async create({ userId, token, expiresAt }) {
    const sql = `
      INSERT INTO password_reset_tokens (user_id, token, expires_at)
      VALUES (?, ?, ?)
    `;

    const [result] = await pool.execute(sql, [userId, token, expiresAt]);
    return this.findById(result.insertId);
  },

  // Aquest mètode busca un token pel seu identificador intern.
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

  // Aquest mètode busca un registre a partir del token rebut.
  // És rellevant perquè permet comprovar si el token de recuperació existeix i es pot validar.  
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

  // Aquest mètode marca un token com a utilitzat.
  // Això evita que el mateix enllaç o codi de recuperació es pugui reutilitzar més d’una vegada.  
  async markAsUsed(id) {
    const sql = `
      UPDATE password_reset_tokens
      SET is_used = 1
      WHERE id = ?
    `;

    await pool.execute(sql, [id]);
    return this.findById(id);
  },

  // Aquest mètode elimina els tokens que ja han caducat o que ja s’han fet servir.
  // És útil per mantenir aquesta taula neta i evitar acumular registres que ja no tenen valor.  
  async deleteExpired() {
    const sql = `
      DELETE FROM password_reset_tokens
      WHERE expires_at < NOW() OR is_used = 1
    `;

    const [result] = await pool.execute(sql);
    return result.affectedRows;
  },

  // Aquest mètode elimina tots els tokens associats a un usuari concret.
  // Pot ser útil, per exemple, quan es vol invalidar qualsevol procés de recuperació anterior.  
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
