const { pool } = require('../config/db');

class CimModel {
  // Crear un nou cim/ruta
  static async create({ name, description, distance, duration, difficulty, latitude, longitude }) {
    const [result] = await pool.query(
      `INSERT INTO mountain_routes
       (name, description, distance, duration, difficulty, latitude, longitude)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [name, description, distance, duration, difficulty, latitude, longitude]
    );
    return result.insertId;
  }

  // Obtenir tots els cims
  static async findAll() {
    const [rows] = await pool.query(
      'SELECT * FROM mountain_routes ORDER BY name ASC'
    );
    return rows;
  }

  // Trobar cim per ID
  static async findById(id) {
    const [rows] = await pool.query(
      'SELECT * FROM mountain_routes WHERE id = ?',
      [id]
    );
    return rows[0];
  }

  // Buscar cims per dificultat
  static async findByDifficulty(difficulty) {
    const [rows] = await pool.query(
      'SELECT * FROM mountain_routes WHERE difficulty = ? ORDER BY name ASC',
      [difficulty]
    );
    return rows;
  }

  // Buscar cims per nom (cerca parcial)
  static async search(searchTerm) {
    const [rows] = await pool.query(
      `SELECT * FROM mountain_routes
       WHERE name LIKE ? OR description LIKE ?
       ORDER BY name ASC`,
      [`%${searchTerm}%`, `%${searchTerm}%`]
    );
    return rows;
  }

  // Actualitzar cim
  static async update(id, { name, description, distance, duration, difficulty, latitude, longitude }) {
    const [result] = await pool.query(
      `UPDATE mountain_routes
       SET name = ?, description = ?, distance = ?, duration = ?,
           difficulty = ?, latitude = ?, longitude = ?
       WHERE id = ?`,
      [name, description, distance, duration, difficulty, latitude, longitude, id]
    );
    return result.affectedRows > 0;
  }

  // Eliminar cim
  static async delete(id) {
    const [result] = await pool.query(
      'DELETE FROM mountain_routes WHERE id = ?',
      [id]
    );
    return result.affectedRows > 0;
  }

  // Obtenir estadístiques
  static async getStats() {
    const [totalRows] = await pool.query(
      'SELECT COUNT(*) as total FROM mountain_routes'
    );

    const [difficultyStats] = await pool.query(
      `SELECT difficulty, COUNT(*) as count
       FROM mountain_routes
       GROUP BY difficulty`
    );

    return {
      total: totalRows[0].total,
      perDifficulty: difficultyStats
    };
  }
}

module.exports = CimModel;
