const pool = require('../config/db');

// Aquest model gestiona l'accés a les fotos associades a les ascensions.
// Centralitza les consultes i insercions sobre ascent_photos, mantenint un
// format de resposta coherent per als serveis que consumeixen aquestes dades.
const AscentPhotoModel = {

  // Insereix diverses fotos vinculades a una mateixa ascensió.
  // S'utilitza quan l'usuari registra una ascensió amb imatges ja pujades
  // prèviament al sistema d'emmagatzematge.
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

    // Recupera les fotos que s'acaben d'inserir per retornar-les amb el
    // mateix format que la resta de consultes del model.
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

  // Retorna totes les fotos d'una ascensió concreta.
  // La consulta comprova també que l'ascensió pertanyi a l'usuari autenticat,
  // evitant que es puguin consultar imatges d'altres comptes.
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

  // Retorna la foto principal de cada ascensió indicada.
  // S'utilitza per mostrar una imatge resum als llistats sense haver de
  // carregar totes les fotos de cada ascensió.
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

    // Organitza les fotos per identificador d'ascensió perquè el servei les
    // pugui associar ràpidament amb el seu registre corresponent.
    const byAscentId = new Map();
    for (const row of rows) {
      if (!byAscentId.has(row.ascent_id)) {
        byAscentId.set(row.ascent_id, row);
      }
    }

    return byAscentId;
  },

  // Retorna les fotos representatives més recents de l'usuari.
  // Només selecciona una foto per ascensió, prioritzant la foto principal i,
  // si no n'hi ha, la imatge més recent d'aquella ascensió.
  async findRecentRepresentativeByUserId(userId, limit = 12) {
    const sql = `
      SELECT
        ap.id,
        ap.ascent_id,
        a.peak_id,
        p.name AS peak_name,
        a.ascent_date,
        ap.storage_path,
        ap.is_primary,
        ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
        AND NOT EXISTS (
          SELECT 1
          FROM ascent_photos ap2
          WHERE ap2.ascent_id = ap.ascent_id
            AND (
              ap2.is_primary > ap.is_primary
              OR (
                ap2.is_primary = ap.is_primary
                AND ap2.created_at > ap.created_at
              )
              OR (
                ap2.is_primary = ap.is_primary
                AND ap2.created_at = ap.created_at
                AND ap2.id > ap.id
              )
            )
        )
      ORDER BY a.ascent_date DESC, a.id DESC
      LIMIT ?
    `;

    const [rows] = await pool.execute(sql, [userId, limit]);
    return rows;
  },

  // Retorna les fotos de totes les ascensions de l'usuari.
  // S'utilitza per construir la galeria completa, ordenada per les ascensions
  // més recents i preparada per carregar-se de manera paginada.
  async findGalleryByUserId(userId, limit, offset = 0) {
    const sql = `
      SELECT
        ap.id,
        ap.ascent_id,
        a.peak_id,
        p.name AS peak_name,
        a.ascent_date,
        ap.storage_path,
        ap.is_primary,
        ap.created_at
      FROM ascent_photos ap
      INNER JOIN ascents a ON a.id = ap.ascent_id
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
      ORDER BY a.ascent_date DESC, a.id DESC, ap.created_at DESC, ap.id DESC
      LIMIT ? OFFSET ?
    `;

    const [rows] = await pool.execute(sql, [userId, limit, offset]);
    return rows;
  },
};

module.exports = AscentPhotoModel;