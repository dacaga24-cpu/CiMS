const pool = require('../config/db');


// Aquest model centralitza l’accés a les dades dels usuaris.
// Permet crear comptes, recuperar perfils i actualitzar informació vinculada al compte.
const UserModel = {

  // Crea un nou usuari a la base de dades.
  // Retorna el registre creat per poder continuar el flux amb les dades actualitzades.
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

  // Busca un usuari a partir del seu identificador.
  // S’utilitza per recuperar les dades visibles del perfil sense exposar la contrasenya.
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

  // Busca un usuari pel seu correu electrònic.
  // És necessari per validar registres existents i gestionar l’inici de sessió.
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

  // Actualitza la contrasenya d’un usuari.
  // La nova contrasenya ja arriba preparada per guardar-se de manera segura.
  async updatePassword(id, hashedPassword) {
    const sql = `
      UPDATE users
      SET password = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [hashedPassword, id]);
    return result.affectedRows;
  },

  // Actualitza el nom i el cognom d’un usuari.
  // Només modifica les dades editables del perfil.
  async updateProfile(id, { firstName, lastName }) {
    const sql = `
      UPDATE users
      SET first_name = ?, last_name = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [firstName, lastName, id]);
    return result.affectedRows;
  },

  // Actualitza la ruta de la foto de perfil.
  // Permet assignar una nova imatge o eliminar-la guardant un valor nul.
  async updateProfilePhoto(id, storagePathOrNull) {
    const sql = `
      UPDATE users
      SET profile_photo_path = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [storagePathOrNull, id]);
    return result.affectedRows;
  },
  // Recupera l’usuari amb la contrasenya inclosa.
  // S’utilitza només per comprovar la contrasenya actual abans de canviar-la.
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

  // Desactiva el compte d’un usuari sense eliminar-lo físicament.
  // Aquesta baixa lògica conserva la coherència de les dades relacionades.
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