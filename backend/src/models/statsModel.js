const pool = require('../config/db');

// Aquest model agrupa les consultes necessàries per construir les estadístiques.
// Calcula resums de progrés, activitat mensual, cims destacats i dades per al dashboard.
const peakPhotosBucketName = process.env.PEAK_PHOTOS_BUCKET_NAME || process.env.GCS_BUCKET_NAME;

// Aquesta consulta afegeix una única foto pública a cada cim.
// Permet mostrar imatges a estadístiques i dashboard sense duplicar resultats.
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

// Construeix una URL pública a partir de la ruta interna de la imatge.
// Si no hi ha imatge configurada, retorna null perquè el frontend pugui usar una imatge de reserva.
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

  // Retorna l’altitud màxima entre els cims completats per l’usuari.
  // Aquest valor permet destacar el cim més alt assolit dins del seu progrés.
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

  // Retorna la suma d’altitud acumulada per les ascensions amb data.
  // El rang opcional permet adaptar la mètrica al període seleccionat a la pantalla.
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

  // Retorna els cims més repetits per l’usuari.
  // S’utilitza per mostrar el rànquing de cims amb més ascensions registrades.
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

  // Retorna el cim amb més ascensions datades de l’usuari.
  // Manté la compatibilitat amb pantalles que només necessiten un únic cim destacat.
  async getMostAscendedPeak(userId) {
    const peaks = await this.getTopAscendedPeaks(userId, 1);
    return peaks.length === 0 ? null : peaks[0];
  },

  // Retorna les ascensions agrupades per any i mes.
  // Aquesta informació alimenta les gràfiques d’activitat mensual.
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

  // Retorna tots els mesos amb activitat de l’usuari.
  // Serveix per calcular ratxes i continuïtat d’activitat des del servei.
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

  // Calcula el progrés del repte de 100 cims únics.
  // Utilitza ascensions datades per establir una finestra temporal fiable.
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

  // Retorna les últimes ascensions datades de l’usuari.
  // Inclou dades del cim i la seva imatge per mostrar activitat recent al dashboard.
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

  // Retorna els cims que tenen una marca concreta activa per a l’usuari.
  // Permet reutilitzar la mateixa consulta per objectius, favorits o completats.
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

  // Retorna les comarques associades a un conjunt de cims.
  // Fa una sola consulta per evitar repetir accessos a la base de dades.
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

// Aquesta funció construeix la condició temporal per filtrar ascensions.
// Només utilitza rangs controlats pel servei per mantenir la consulta segura.
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