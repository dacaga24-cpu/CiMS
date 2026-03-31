const { pool } = require('../config/db');

class AscensioModel {
  // Crear una nova ascensió (necessitem crear la taula primer)
  static async create({ user_id, route_id, data_ascensio, notes }) {
    const [result] = await pool.query(
      `INSERT INTO ascensions (user_id, route_id, data_ascensio, notes)
       VALUES (?, ?, ?, ?)`,
      [user_id, route_id, data_ascensio, notes]
    );
    return result.insertId;
  }

  // Obtenir totes les ascensions d'un usuari
  static async findByUserId(userId) {
    const [rows] = await pool.query(
      `SELECT a.*, m.name as route_name, m.difficulty, m.distance
       FROM ascensions a
       JOIN mountain_routes m ON a.route_id = m.id
       WHERE a.user_id = ?
       ORDER BY a.data_ascensio DESC`,
      [userId]
    );
    return rows;
  }

  // Obtenir totes les ascensions d'una ruta
  static async findByRouteId(routeId) {
    const [rows] = await pool.query(
      `SELECT a.*, u.username
       FROM ascensions a
       JOIN users u ON a.user_id = u.id
       WHERE a.route_id = ?
       ORDER BY a.data_ascensio DESC`,
      [routeId]
    );
    return rows;
  }

  // Trobar ascensió per ID
  static async findById(id) {
    const [rows] = await pool.query(
      `SELECT a.*, m.name as route_name, u.username
       FROM ascensions a
       JOIN mountain_routes m ON a.route_id = m.id
       JOIN users u ON a.user_id = u.id
       WHERE a.id = ?`,
      [id]
    );
    return rows[0];
  }

  // Actualitzar ascensió
  static async update(id, { data_ascensio, notes }) {
    const [result] = await pool.query(
      `UPDATE ascensions
       SET data_ascensio = ?, notes = ?
       WHERE id = ?`,
      [data_ascensio, notes, id]
    );
    return result.affectedRows > 0;
  }

  // Eliminar ascensió
  static async delete(id) {
    const [result] = await pool.query(
      'DELETE FROM ascensions WHERE id = ?',
      [id]
    );
    return result.affectedRows > 0;
  }

  // Comprovar si un usuari ja ha fet una ruta
  static async hasUserCompletedRoute(userId, routeId) {
    const [rows] = await pool.query(
      `SELECT COUNT(*) as count
       FROM ascensions
       WHERE user_id = ? AND route_id = ?`,
      [userId, routeId]
    );
    return rows[0].count > 0;
  }

  // Estadístiques d'un usuari
  static async getUserStats(userId) {
    const [stats] = await pool.query(
      `SELECT
         COUNT(*) as total_ascensions,
         COUNT(DISTINCT route_id) as unique_routes,
         SUM(m.distance) as total_distance
       FROM ascensions a
       JOIN mountain_routes m ON a.route_id = m.id
       WHERE a.user_id = ?`,
      [userId]
    );
    return stats[0];
  }
}

module.exports = AscensioModel;
