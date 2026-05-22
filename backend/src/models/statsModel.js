const pool = require('../config/db');

// Aquest model agrupa les consultes agregades específiques per a la pantalla
// d'estadístiques. Es manté separat dels models de domini perquè aquí es
// resolen càlculs, JOINs i resums pensats per alimentar vistes de progrés.
//
// Les ascensions sense data no formen part de les estadístiques temporals.
// Serveixen per marcar un cim com a completat, però no sumen metres, historial,
// repte, gràfiques mensuals ni últimes ascensions.
const peakPhotosBucketName = process.env.PEAK_PHOTOS_BUCKET_NAME || process.env.GCS_BUCKET_NAME;

// Aquesta consulta reutilitzable recupera una única foto per cim.
// Permet afegir imatges al dashboard i a les estadístiques sense duplicar files
// si més endavant un cim té diverses fotos associades.
const PEAK_PHOTO_JOIN = `
  LEFT JOIN (
    SELECT pp.peak_id, pp.storage_path
    FROM peak_photos pp
    INNER JOIN (
      SELECT peak_id, MIN(id) AS id
      FROM peak_photos
      GROUP BY peak_id
    ) first_photo ON first_photo.id = pp.id
  ) pp ON pp.peak_id = p.id
`;

// Aquesta funció transforma la ruta interna del bucket en una URL pública.
// Si no hi ha imatge o no hi ha bucket configurat, retorna null perquè el
// frontend pugui mantenir la imatge local de reserva.
function buildPublicImageUrl(storagePath) {
  if (!storagePath || !peakPhotosBucketName) {
    return null;
  }

  const encodedPath = storagePath
    .split('/')
    .map(encodeURIComponent)
    .join('/');

  return `https://storage.googleapis.com/${peakPhotosBucketName}/${encodedPath}`;
}

const StatsModel = {

  // Retorna l'altitud màxima entre els cims completats per l'usuari.
  // Aquest valor depèn de l'estat completat del cim, no de la cronologia
  // d'ascensions, perquè un cim pot estar completat amb un registre sense data.
  async getHighestCompletedAltitude(userId) {
    const sql = `
      SELECT MAX(p.altitude) AS highest_altitude
      FROM peak_status ps
      INNER JOIN peaks p ON p.id = ps.peak_id
      WHERE ps.user_id = ? AND ps.is_completed = 1
    `;

    const [rows] = await pool.execute(sql, [userId]);
    const value = rows[0] ? rows[0].highest_altitude : null;
    return value === null ? null : Number(value);
  },

  // Retorna la suma d'altitud acumulada per les ascensions amb data.
  // Accepta un rang temporal opcional per alimentar el selector de la pantalla
  // d'estadístiques sense duplicar consultes específiques.
  async getTotalAltitudeMeters(userId, range = 'total') {
    const rangeCondition = buildAscentDateRangeCondition(range);

    const sql = `
      SELECT COALESCE(SUM(p.altitude), 0) AS total_altitude
      FROM ascents a
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
        AND a.ascent_date IS NOT NULL
        ${rangeCondition}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows[0] ? Number(rows[0].total_altitude) : 0;
  },

  // Retorna els cims més coronats per l'usuari.
  // Es fa servir per mostrar el top 3 de cims amb més ascensions registrades.
  async getTopAscendedPeaks(userId, limit = 3) {
    const safeLimit = Number.isInteger(limit) && limit > 0
      ? Math.min(limit, 10)
      : 3;

    const sql = `
      SELECT
        a.peak_id,
        p.name AS peak_name,
        p.altitude AS peak_altitude,
        pp.storage_path AS photo_storage_path,
        COUNT(*) AS ascent_count
      FROM ascents a
      INNER JOIN peaks p ON p.id = a.peak_id
      ${PEAK_PHOTO_JOIN}
      WHERE a.user_id = ?
        AND a.ascent_date IS NOT NULL
      GROUP BY a.peak_id, p.name, p.altitude, pp.storage_path
      ORDER BY ascent_count DESC, p.altitude DESC, p.name ASC
      LIMIT ${safeLimit}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows.map((row) => ({
      peakId: Number(row.peak_id),
      peakName: row.peak_name,
      peakAltitude: Number(row.peak_altitude),
      count: Number(row.ascent_count),
      imageUrl: buildPublicImageUrl(row.photo_storage_path),
    }));
  },

  // Retorna el cim amb més ascensions datades de l'usuari.
  // Es manté per compatibilitat amb el contracte anterior, però internament
  // aprofita el mateix criteri que el top de cims més coronats.
  async getMostAscendedPeak(userId) {
    const peaks = await this.getTopAscendedPeaks(userId, 1);
    return peaks.length === 0 ? null : peaks[0];
  },

  // Retorna el nombre d'ascensions agrupades per any i mes.
  // Només inclou ascensions amb data, ja que els registres sense data no es
  // poden ubicar dins d'una gràfica mensual.
  async getMonthlyAscentsRaw(userId, monthsBack) {
    const sql = `
      SELECT
        YEAR(ascent_date) AS year,
        MONTH(ascent_date) AS month,
        COUNT(*) AS ascent_count
      FROM ascents
      WHERE user_id = ?
        AND ascent_date IS NOT NULL
        AND ascent_date >= DATE_SUB(
          DATE_FORMAT(CURDATE(), '%Y-%m-01'),
          INTERVAL ? MONTH
        )
      GROUP BY YEAR(ascent_date), MONTH(ascent_date)
      ORDER BY year ASC, month ASC
    `;

    const [rows] = await pool.execute(sql, [userId, monthsBack - 1]);
    return rows.map((row) => ({
      year: Number(row.year),
      month: Number(row.month),
      count: Number(row.ascent_count),
    }));
  },

  // Retorna tots els mesos amb activitat de l'usuari.
  // Aquesta informació permet calcular ratxes mensuals actuals i històriques
  // des del servei sense traslladar aquesta lògica a la base de dades.
  async getMonthlyActivityRaw(userId) {
    const sql = `
      SELECT
        YEAR(ascent_date) AS year,
        MONTH(ascent_date) AS month,
        COUNT(*) AS ascent_count
      FROM ascents
      WHERE user_id = ?
        AND ascent_date IS NOT NULL
      GROUP BY YEAR(ascent_date), MONTH(ascent_date)
      ORDER BY year ASC, month ASC
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows.map((row) => ({
      year: Number(row.year),
      month: Number(row.month),
      count: Number(row.ascent_count),
    }));
  },

  // Calcula el progrés del repte rolling de 100 cims únics.
  // La finestra es calcula només amb ascensions datades, perquè el repte
  // necessita una referència temporal fiable.
  async getChallengeProgress(userId) {
    const sql = `
      SELECT
        DATE_SUB(MAX(ascent_date), INTERVAL 1 YEAR) AS window_start,
        MAX(ascent_date) AS window_end,
        (
          SELECT COUNT(DISTINCT peak_id)
          FROM ascents
          WHERE user_id = ?
            AND ascent_date IS NOT NULL
            AND ascent_date >= DATE_SUB(
              (
                SELECT MAX(ascent_date)
                FROM ascents
                WHERE user_id = ?
                  AND ascent_date IS NOT NULL
              ),
              INTERVAL 1 YEAR
            )
        ) AS completed_in_window
      FROM ascents
      WHERE user_id = ?
        AND ascent_date IS NOT NULL
    `;

    const [rows] = await pool.execute(sql, [userId, userId, userId]);
    if (rows.length === 0 || rows[0].window_end === null) {
      return {
        completed: 0,
        target: 100,
        windowStart: null,
        windowEnd: null,
      };
    }

    return {
      completed: Number(rows[0].completed_in_window),
      target: 100,
      windowStart: rows[0].window_start,
      windowEnd: rows[0].window_end,
    };
  },

  // Retorna les últimes ascensions datades de l'usuari amb informació del cim.
  // També incorpora la imatge pública del cim perquè el dashboard pugui mostrar
  // una miniatura real de la muntanya associada a cada ascensió.
  async getRecentAscentsRaw(userId, limit) {
    const safeLimit = Number.isInteger(limit) && limit > 0 ? limit : 5;

    const sql = `
      SELECT
        a.id,
        a.peak_id,
        a.ascent_date,
        a.notes,
        p.name AS peak_name,
        p.altitude AS peak_altitude,
        pp.storage_path AS photo_storage_path
      FROM ascents a
      INNER JOIN peaks p ON p.id = a.peak_id
      ${PEAK_PHOTO_JOIN}
      WHERE a.user_id = ?
        AND a.ascent_date IS NOT NULL
      ORDER BY a.ascent_date DESC, a.id DESC
      LIMIT ${safeLimit}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows.map((row) => ({
      id: Number(row.id),
      peakId: Number(row.peak_id),
      peakName: row.peak_name,
      peakAltitude: Number(row.peak_altitude),
      ascentDate: row.ascent_date,
      notes: row.notes,
      imageUrl: buildPublicImageUrl(row.photo_storage_path),
    }));
  },

  // Retorna els cims que tenen un flag concret actiu al peak_status d'un usuari.
  // S'utilitza per llistar objectius, preferits o completats sense duplicar
  // consultes específiques per a cada tipus d'estat.
  async findFlaggedPeaks(userId, flagColumn, limit) {
    const allowedFlags = ['is_target', 'is_favorite', 'is_completed'];
    if (!allowedFlags.includes(flagColumn)) {
      throw new Error(`Invalid flag column requested: ${flagColumn}`);
    }

    const safeLimit = Number.isInteger(limit) && limit > 0 ? limit : 5;
    const sql = `
      SELECT
        p.id AS peak_id,
        p.name AS peak_name,
        p.altitude AS peak_altitude,
        pp.storage_path AS photo_storage_path
      FROM peak_status ps
      INNER JOIN peaks p ON p.id = ps.peak_id
      ${PEAK_PHOTO_JOIN}
      WHERE ps.user_id = ? AND ps.${flagColumn} = 1
      ORDER BY ps.updated_at DESC, p.name ASC
      LIMIT ${safeLimit}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows.map((row) => ({
      peakId: Number(row.peak_id),
      peakName: row.peak_name,
      peakAltitude: Number(row.peak_altitude),
      imageUrl: buildPublicImageUrl(row.photo_storage_path),
    }));
  },

  // Retorna les comarques associades a un conjunt de cims en una sola consulta.
  // Això evita fer una consulta individual per cada cim mostrat a estadístiques
  // o al dashboard.
  async getRegionsForPeaks(peakIds) {
    const result = new Map();
    if (!Array.isArray(peakIds) || peakIds.length === 0) {
      return result;
    }

    const placeholders = peakIds.map(() => '?').join(', ');
    const sql = `
      SELECT pr.peak_id, r.name
      FROM peak_regions pr
      INNER JOIN regions r ON r.id = pr.region_id
      WHERE pr.peak_id IN (${placeholders})
      ORDER BY r.name ASC
    `;

    const [rows] = await pool.execute(sql, peakIds);
    for (const row of rows) {
      const peakId = Number(row.peak_id);
      if (!result.has(peakId)) {
        result.set(peakId, []);
      }
      result.get(peakId).push(row.name);
    }

    return result;
  },
};

// Aquesta funció construeix la condició temporal per a consultes d'ascensions.
// Només accepta valors interns controlats pel servei per evitar SQL dinàmic insegur.
function buildAscentDateRangeCondition(range) {
  switch (range) {
    case 'month':
      return `
        AND a.ascent_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
      `;
    case 'quarter':
      return `
        AND a.ascent_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
      `;
    case 'six_months':
      return `
        AND a.ascent_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
      `;
    case 'year':
      return `
        AND a.ascent_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
      `;
    case 'total':
    default:
      return '';
  }
}

module.exports = StatsModel;