const pool = require('../config/db');


// Aquest model centralitza l'accés a les dades dels usuaris.
// La seva funció és crear usuaris, buscar-los i actualitzar informació concreta
// relacionada amb el compte dins de la base de dades.
const UserModel = {

  // Aquest mètode crea un nou usuari a la base de dades.
  // Rep les dades bàsiques del compte i retorna el registre complet un cop ja s'ha guardat.
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

  // Aquest mètode busca un usuari a partir del seu identificador.
  // És rellevant quan cal recuperar el perfil d'un usuari concret dins de l'aplicació.
  async findById(id) {
    const sql = `
      SELECT id, first_name, last_name, email, is_active, created_at, updated_at
      FROM users
      WHERE id = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [id]);
    return rows[0] || null;
  },

  // Aquest mètode busca un usuari pel seu correu electrònic.
  // Es fa servir sobretot per comprovar si ja existeix un compte
  // i per recuperar les dades necessàries durant l'inici de sessió.
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

  // Aquest mètode actualitza la contrasenya d'un usuari concret.
  // Rep l'identificador de l'usuari i la nova contrasenya ja preparada per ser guardada.
  async updatePassword(id, hashedPassword) {
    const sql = `
      UPDATE users
      SET password = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [hashedPassword, id]);
    return result.affectedRows;
  },

  // Aquest mètode actualitza el nom i el cognom d'un usuari concret.
  // Només modifica els camps editables del perfil, deixant intactes les dades
  // que l'usuari no pot canviar directament, com el correu o la contrasenya.
  async updateProfile(id, { firstName, lastName }) {
    const sql = `
      UPDATE users
      SET first_name = ?, last_name = ?
      WHERE id = ?
    `;
    const [result] = await pool.execute(sql, [firstName, lastName, id]);
    return result.affectedRows;
  },
};

module.exports = UserModel;