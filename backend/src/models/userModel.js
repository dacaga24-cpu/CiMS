const pool = require('../config/db');


// Model d'usuari — única capa que parla amb la base de dades.
// Cap altre fitxer del projecte ha d'executar SQL directament.
const UserModel = {

  // Insereix un nou usuari a la base de dades.
  // Rep les dades ja validades i la contrasenya ja encriptada.
  // Retorna l'objecte complet de l'usuari creat (fent una consulta amb findById).
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

  // Busca un usuari pel seu id.
  // Retorna l'objecte usuari o null si no existeix.
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

  // Busca un usuari pel seu email.
  // Utilitzat pel service per comprovar duplicats (registre)
  // i per recuperar l'usuari al fer login.
  // Retorna l'objecte usuari o null si no existeix.
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