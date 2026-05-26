const pool = require('../config/db');

// Aquest model centralitza l’accés a les fotos associades a les ascensions.
// Permet crear, consultar, llistar i eliminar imatges mantenint la propietat de cada usuari.
const AscentPhotoModel = {

  // Insereix diverses fotos vinculades a una mateixa ascensió.
  // També permet identificar la imatge principal o l’evidència d’una verificació.
  async createMany(ascentId, photos, connection) {
    if (!Array.isArray(photos) || photos.length === 0) {
      return [];
    }

    const executor = connection || pool;
    const placeholders = photos.map(() => '(?, ?, ?, ?)').join(', ');
    const params = [];

    for (const photo of photos) {
      params.push(
        ascentId,
        photo.storagePath,
        photo.isPrimary ? 1 : 0,
        photo.isVerificationEvidence ? 1 : 0
      );
    }

    const sql = `
      INSERT INTO ascent_photos (
        ascent_id,
        storage_path,
        is_primary,
        is_verification_evidence
      )
      VALUES ${placeholders}
    `;

    const [insertResult] = await executor.execute(sql, params);

    const firstId = insertResult.insertId;
    const lastId = firstId + photos.length - 1;

    const [rows] = await executor.execute(
      `SELECT id, ascent_id, storage_path, is_primary, is_verification_evidence, created_at
       FROM ascent_photos
       WHERE id BETWEEN ? AND ?
       ORDER BY id ASC`,
      [firstId, lastId]
    );

    return rows;
  },

  // Retorna totes les fotos d’una ascensió concreta.
  // La consulta comprova que l’ascensió pertanyi a l’usuari autenticat.
  async findAllByAscentIdAndUserId(ascentId, userId) {
    const sql = `
      SELECT ap.id, ap.ascent_id, ap.storage_path, ap.is_primary, ap.is_verification_evidence, ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      WHERE ap.ascent_id = ? AND a.user_id = ?
      ORDER BY ap.is_primary DESC, ap.id ASC
    `;

    const [rows] = await pool.execute(sql, [ascentId, userId]);
    return rows;
  },

  // Retorna una foto concreta només si pertany a una ascensió de l’usuari.
  // Aquesta comprovació protegeix les imatges abans de permetre accions sensibles.
  async findByIdAndUserId(photoId, userId) {
    const sql = `
      SELECT ap.id, ap.ascent_id, ap.storage_path, ap.is_primary, ap.is_verification_evidence, ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      WHERE ap.id = ? AND a.user_id = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [photoId, userId]);
    return rows[0] || null;
  },

  // Retorna la foto principal de cada ascensió indicada.
  // Serveix per mostrar imatges resum en llistats sense carregar tota la galeria.
  async findPrimaryByAscentIds(ascentIds) {
    if (!Array.isArray(ascentIds) || ascentIds.length === 0) {
      return new Map();
    }

    const placeholders = ascentIds.map(() => '?').join(', ');
    const sql = `
      SELECT id, ascent_id, storage_path, is_primary, is_verification_evidence, created_at
      FROM ascent_photos
      WHERE ascent_id IN (${placeholders}) AND is_primary = 1
    `;

    const [rows] = await pool.execute(sql, ascentIds);

    const byAscentId = new Map();

    for (const row of rows) {
      if (!byAscentId.has(row.ascent_id)) {
        byAscentId.set(row.ascent_id, row);
      }
    }

    return byAscentId;
  },

  // Retorna les fotos més recents pujades per l’usuari.
  // Aquesta informació permet mostrar activitat visual recent al dashboard.
  async findRecentByUserId(userId, limit = 12) {
    const safeLimit = Number.isInteger(Number(limit))
      ? Math.min(Math.max(Number(limit), 1), 50)
      : 12;

    const sql = `
      SELECT
        ap.id,
        ap.ascent_id,
        a.peak_id,
        p.name AS peak_name,
        a.ascent_date,
        ap.storage_path,
        ap.is_primary,
        ap.is_verification_evidence,
        ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
      ORDER BY ap.created_at DESC, ap.id DESC
      LIMIT ${safeLimit}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows;
  },

  // Retorna les fotos de totes les ascensions de l’usuari.
  // S’utilitza per construir una galeria completa amb càrrega paginada.
  async findGalleryByUserId(userId, limit, offset = 0) {
    const safeLimit = Number.isInteger(Number(limit))
      ? Math.min(Math.max(Number(limit), 1), 50)
      : 12;

    const safeOffset = Number.isInteger(Number(offset))
      ? Math.max(Number(offset), 0)
      : 0;

    const sql = `
      SELECT
        ap.id,
        ap.ascent_id,
        a.peak_id,
        p.name AS peak_name,
        a.ascent_date,
        ap.storage_path,
        ap.is_primary,
        ap.is_verification_evidence,
        ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
      ORDER BY a.ascent_date DESC, a.id DESC, ap.created_at DESC, ap.id DESC
      LIMIT ${safeLimit} OFFSET ${safeOffset}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows;
  },

  // Elimina una foto concreta només si pertany a una ascensió de l’usuari.
  // Aquesta comprovació evita que un compte pugui esborrar imatges alienes.
  async deleteByIdAndUserId(photoId, userId) {
    const sql = `
      DELETE ap
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      WHERE ap.id = ? AND a.user_id = ?
    `;

    const [result] = await pool.execute(sql, [photoId, userId]);
    return result.affectedRows;
  },

  // Marca com a principal la primera foto disponible d’una ascensió.
  // S’utilitza quan s’elimina la imatge principal i encara queden altres fotos.
  async promoteFirstPhotoAsPrimary(ascentId) {
    const sql = `
      UPDATE ascent_photos
      SET is_primary = 1
      WHERE ascent_id = ?
      ORDER BY created_at ASC, id ASC
      LIMIT 1
    `;

    const [result] = await pool.execute(sql, [ascentId]);
    return result.affectedRows;
  },
};

module.exports = AscentPhotoModel;