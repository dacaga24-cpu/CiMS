const pool = require('../config/db');

// Accés a la taula users.
const UserModel = {

  // Crea un usuari i retorna el registre complet amb les columnes públiques.
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

  // Cerca per id. Retorna camps públics (sense contrasenya).
  async findById(id) {
    const sql = `
      SELECT id, first_name, last_name, email, is_active, profile_photo_path, created_at, updated_at
      FROM users
      WHERE id = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [id]);
    return rows[0] || null;
  },

  // Cerca per email. Inclou la contrasenya perquè s'utilitza durant el login.
  async findByEmail(email) {
    const sql = `
      SELECT id, first_name, last_name, email, password, is_active, profile_photo_path, created_at, updated_at
      FROM users
      WHERE email = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [email]);
    return rows[0] || null;
  },

  async updatePassword(id, hashedPassword) {
    const sql = `
      UPDATE users
      SET password = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [hashedPassword, id]);
    return result.affectedRows;
  },

  async updateProfile(id, { firstName, lastName }) {
    const sql = `
      UPDATE users
      SET first_name = ?, last_name = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [firstName, lastName, id]);
    return result.affectedRows;
  },

  // Acceptar NULL permet usar el mateix mètode per assignar i per esborrar
  // la foto de perfil sense duplicar lògica.
  async updateProfilePhoto(id, storagePathOrNull) {
    const sql = `
      UPDATE users
      SET profile_photo_path = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [storagePathOrNull, id]);
    return result.affectedRows;
  },

  // Recupera l'usuari amb la contrasenya inclosa. Només per verificar la
  // contrasenya actual abans d'un canvi; mai per retornar dades al client.
  async findByIdWithPassword(id) {
    const sql = `
      SELECT id, password
      FROM users
      WHERE id = ?
      LIMIT 1
    `;
    const [rows] = await pool.execute(sql, [id]);
    return rows[0] || null;
  },

  // Soft delete (is_active=false) per preservar la integritat de les dades
  // relacionades (ascensions, estadístiques) i permetre reactivar el compte.
  async deactivateAccount(id) {
    const sql = `
      UPDATE users
      SET is_active = false
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [id]);
    return result.affectedRows;
  },
};

module.exports = UserModel;
