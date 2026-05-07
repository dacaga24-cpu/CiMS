const pool = require('../config/db');

// Accés a la taula ascent_photos. Mètodes parametritzats per evitar SQLi.
// La majoria accepten una `connection` opcional perquè els serveis puguin
// executar-los dins d'una transacció iniciada amb pool.getConnection().
const AscentPhotoModel = {

  // Insereix múltiples fotos del mateix ascens en una sola query, dins de
  // la transacció que crea l'ascens si el caller hi passa connection.
  async createMany(ascentId, photos, connection) {
    if (!Array.isArray(photos) || photos.length === 0) {
      return [];
    }

    const executor = connection || pool;
    const placeholders = photos.map(() => '(?, ?, ?)').join(', ');
    const params = [];
    for (const photo of photos) {
      params.push(ascentId, photo.storagePath, photo.isPrimary ? 1 : 0);
    }

    const sql = `
      INSERT INTO ascent_photos (ascent_id, storage_path, is_primary)
      VALUES ${placeholders}
    `;

    const [insertResult] = await executor.execute(sql, params);

    // Restringim al rang d'ids generat per aquesta inserció (InnoDB els
    // assigna consecutius des d'insertId), així no llegim files antigues
    // del mateix ascens.
    const firstId = insertResult.insertId;
    const lastId = firstId + photos.length - 1;
    const [rows] = await executor.execute(
      `SELECT id, ascent_id, storage_path, is_primary, created_at
       FROM ascent_photos
       WHERE id BETWEEN ? AND ?
       ORDER BY id ASC`,
      [firstId, lastId]
    );
    return rows;
  },

  // Totes les fotos d'un ascens, només si pertany a l'usuari indicat. El
  // JOIN amb ascents fa la comprovació d'ownership a nivell de query, així
  // un reorden futur del flux no obre una via d'IDOR.
  async findAllByAscentIdAndUserId(ascentId, userId) {
    const sql = `
      SELECT ap.id, ap.ascent_id, ap.storage_path, ap.is_primary, ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      WHERE ap.ascent_id = ? AND a.user_id = ?
      ORDER BY ap.is_primary DESC, ap.id ASC
    `;
    const [rows] = await pool.execute(sql, [ascentId, userId]);
    return rows;
  },

  // Fotos principals d'un conjunt d'ascens en una sola query (evita N+1).
  // No filtra per user_id perquè el caller ja ha consultat els ascens amb
  // ownership; els ascentIds passats aquí ja són de l'usuari autenticat.
  async findPrimaryByAscentIds(ascentIds) {
    if (!Array.isArray(ascentIds) || ascentIds.length === 0) {
      return new Map();
    }

    const placeholders = ascentIds.map(() => '?').join(', ');
    const sql = `
      SELECT id, ascent_id, storage_path, is_primary, created_at
      FROM ascent_photos
      WHERE ascent_id IN (${placeholders}) AND is_primary = 1
    `;
    const [rows] = await pool.execute(sql, ascentIds);

    // Map<ascentId, photo> perquè el caller assigni la principal a cada
    // ascens en una sola passada. Si hi ha incoherències antigues amb
    // múltiples principals (que el servei ja no permet), es queda la
    // primera fila i descarta la resta.
    const byAscentId = new Map();
    for (const row of rows) {
      if (!byAscentId.has(row.ascent_id)) {
        byAscentId.set(row.ascent_id, row);
      }
    }
    return byAscentId;
  },
};

module.exports = AscentPhotoModel;
