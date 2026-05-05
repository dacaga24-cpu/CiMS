const pool = require('../config/db');

// Aquest model centralitza l'accés a les dades de la taula ascent_photos.
// Manté la mateixa convenció que la resta de models: SELECTs explícits per
// fixar el format de resposta i mètodes parametritzats per evitar SQLi.
//
// La majoria de mètodes accepten una `connection` opcional perquè els
// serveis puguin executar-los dins d'una transacció iniciada amb
// pool.getConnection(). Quan no es passa, es fa servir el pool directament.
const AscentPhotoModel = {

  // Insereix múltiples fotos associades al mateix ascens en una sola query.
  // S'usa des de la creació d'ascens, on el conjunt complet de fotos és
  // conegut a priori i interessa que totes s'insereixin atòmicament dins
  // de la mateixa transacció que crea l'ascens. Si el caller no passa una
  // connection, es fa servir el pool, però llavors no hi ha garantia
  // d'atomicitat amb la inserció de l'ascens.
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

    // El SELECT es restringeix als ids generats per aquesta inserció (un
    // INSERT múltiple a InnoDB assigna ids consecutius començant per
    // insertId). Així el resultat només conté les files acabades d'inserir,
    // mai files pre-existents per a aquest mateix ascens.
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

  // Retorna totes les fotos d'un ascens concret, però només si l'ascens
  // pertany a l'usuari indicat. El JOIN amb ascents fa la comprovació
  // d'ownership a nivell de query, evitant que un reorden futur del flux
  // que cridi aquest mètode obri una via d'IDOR. Si l'ascens no existeix
  // o és d'un altre usuari, retorna una llista buida.
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
};

module.exports = AscentPhotoModel;
