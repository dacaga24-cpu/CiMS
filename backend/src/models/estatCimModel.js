const { pool } = require('../config/db');

class EstatCimModel {
  // Crear o actualitzar l'estat d'un cim per un usuari
  static async upsert({ user_id, route_id, estat, notes }) {
    // Estats possibles: 'pendent', 'completat', 'favorit', 'planificat'
    const [existing] = await pool.query(
      'SELECT id FROM route_states WHERE user_id = ? AND route_id = ?',
      [user_id, route_id]
    );

    if (existing.length > 0) {
      // Actualitzar
      const [result] = await pool.query(
        `UPDATE route_states
         SET estat = ?, notes = ?, updated_at = CURRENT_TIMESTAMP
         WHERE user_id = ? AND route_id = ?`,
        [estat, notes, user_id, route_id]
      );
      return existing[0].id;
    } else {
      // Crear
      const [result] = await pool.query(
        `INSERT INTO route_states (user_id, route_id, estat, notes)
         VALUES (?, ?, ?, ?)`,
        [user_id, route_id, estat, notes]
      );
      return result.insertId;
    }
  }

  // Obtenir l'estat d'una ruta per un usuari
  static async findByUserAndRoute(userId, routeId) {
    const [rows] = await pool.query(
      `SELECT rs.*, m.name as route_name
       FROM route_states rs
       JOIN mountain_routes m ON rs.route_id = m.id
       WHERE rs.user_id = ? AND rs.route_id = ?`,
      [userId, routeId]
    );
    return rows[0];
  }

  // Obtenir tots els estats d'un usuari
  static async findByUserId(userId, estat = null) {
    let query = `
      SELECT rs.*, m.name, m.difficulty, m.distance, m.duration
      FROM route_states rs
      JOIN mountain_routes m ON rs.route_id = m.id
      WHERE rs.user_id = ?
    `;
    const params = [userId];

    if (estat) {
      query += ' AND rs.estat = ?';
      params.push(estat);
    }

    query += ' ORDER BY rs.updated_at DESC';

    const [rows] = await pool.query(query, params);
    return rows;
  }

  // Obtenir favorits d'un usuari
  static async getFavorites(userId) {
    return await this.findByUserId(userId, 'favorit');
  }

  // Obtenir rutes completades
  static async getCompleted(userId) {
    return await this.findByUserId(userId, 'completat');
  }

  // Obtenir rutes planificades
  static async getPlanned(userId) {
    return await this.findByUserId(userId, 'planificat');
  }

  // Marcar com a favorit
  static async toggleFavorite(userId, routeId) {
    const current = await this.findByUserAndRoute(userId, routeId);

    if (current && current.estat === 'favorit') {
      // Treure de favorits
      await pool.query(
        'DELETE FROM route_states WHERE user_id = ? AND route_id = ?',
        [userId, routeId]
      );
      return false;
    } else {
      // Afegir a favorits
      await this.upsert({
        user_id: userId,
        route_id: routeId,
        estat: 'favorit',
        notes: null
      });
      return true;
    }
  }

  // Eliminar estat
  static async delete(userId, routeId) {
    const [result] = await pool.query(
      'DELETE FROM route_states WHERE user_id = ? AND route_id = ?',
      [userId, routeId]
    );
    return result.affectedRows > 0;
  }

  // Estadístiques per usuari
  static async getUserStats(userId) {
    const [stats] = await pool.query(
      `SELECT
         estat,
         COUNT(*) as count
       FROM route_states
       WHERE user_id = ?
       GROUP BY estat`,
      [userId]
    );
    return stats;
  }
}

module.exports = EstatCimModel;
