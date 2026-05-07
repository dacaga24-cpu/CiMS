const pool = require('../config/db');

// Consultes agregades específiques de la pantalla d'estadístiques. Es manté
// separat dels models de domini perquè aquí viuen JOINs i agregacions que
// només serveixen aquesta vista.
const StatsModel = {

  // Altitud màxima entre els cims que l'usuari té com a assolits. Retorna
  // null si encara no n'ha completat cap (el servei distingeix aquest cas
  // d'un zero ambigu).
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

  // Suma d'altitud acumulada per totes les ascensions. Cada ascensió compta
  // per separat (pujar tres vegades el mateix cim suma tres vegades).
  async getTotalAltitudeMeters(userId) {
    const sql = `
      SELECT COALESCE(SUM(p.altitude), 0) AS total_altitude
      FROM ascents a
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows[0] ? Number(rows[0].total_altitude) : 0;
  },

  // Cim que l'usuari ha pujat més vegades. Empats per nombre d'ascensions
  // es desempaten per altitud descendent (resultat determinístic).
  async getMostAscendedPeak(userId) {
    const sql = `
      SELECT a.peak_id, p.name AS peak_name, p.altitude AS peak_altitude, COUNT(*) AS ascent_count
      FROM ascents a
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
      GROUP BY a.peak_id, p.name, p.altitude
      ORDER BY ascent_count DESC, p.altitude DESC
      LIMIT 1
    `;

    const [rows] = await pool.execute(sql, [userId]);
    if (rows.length === 0) {
      return null;
    }
    return {
      peakId: Number(rows[0].peak_id),
      peakName: rows[0].peak_name,
      peakAltitude: Number(rows[0].peak_altitude),
      count: Number(rows[0].ascent_count),
    };
  },

  // Ascensions agrupades per any+mes. Només mesos amb activitat real; el
  // servei completa amb count zero perquè l'array tingui mida fixa al client.
  async getMonthlyAscentsRaw(userId, monthsBack) {
    const sql = `
      SELECT
        YEAR(ascent_date) AS year,
        MONTH(ascent_date) AS month,
        COUNT(*) AS ascent_count
      FROM ascents
      WHERE user_id = ?
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

  // Progrés del repte rolling de 100 cims únics. La finestra acaba a la
  // data de l'última ascensió i s'estén un any cap enrere; cada nova
  // ascensió desplaça la finestra. Es compten cims únics (l'enunciat és
  // "100 cims diferents", no "100 ascensions").
  async getChallengeProgress(userId) {
    const sql = `
      SELECT
        DATE_SUB(MAX(ascent_date), INTERVAL 1 YEAR) AS window_start,
        MAX(ascent_date) AS window_end,
        (
          SELECT COUNT(DISTINCT peak_id)
          FROM ascents
          WHERE user_id = ?
            AND ascent_date >= DATE_SUB(
              (SELECT MAX(ascent_date) FROM ascents WHERE user_id = ?),
              INTERVAL 1 YEAR
            )
        ) AS completed_in_window
      FROM ascents
      WHERE user_id = ?
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

  // Últimes ascensions amb info enriquida del cim. Les comarques es resolen
  // en una segona query batch al servei per evitar duplicació de files.
  async getRecentAscentsRaw(userId, limit) {
    // El límit s'interpola perquè mysql2 no suporta LIMIT parametritzat en
    // totes les versions. El valor sempre és un enter validat al servei.
    const safeLimit = Number.isInteger(limit) && limit > 0 ? limit : 5;
    const sql = `
      SELECT
        a.id, a.peak_id, a.ascent_date, a.notes,
        p.name AS peak_name, p.altitude AS peak_altitude
      FROM ascents a
      INNER JOIN peaks p ON p.id = a.peak_id
      WHERE a.user_id = ?
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
    }));
  },

  // Cims amb un flag concret actiu al peak_status d'un usuari. S'usa des
  // del dashboard per pendents (is_target) i preferits (is_favorite).
  //
  // El nom de columna del flag s'interpola perquè mysql2 no parametritza
  // identificadors. La whitelist garanteix que mai sigui input d'usuari
  // i, per tant, no és un vector d'injecció.
  async findFlaggedPeaks(userId, flagColumn, limit) {
    const allowedFlags = ['is_target', 'is_favorite', 'is_completed'];
    if (!allowedFlags.includes(flagColumn)) {
      throw new Error(`Invalid flag column requested: ${flagColumn}`);
    }

    const safeLimit = Number.isInteger(limit) && limit > 0 ? limit : 5;
    const sql = `
      SELECT p.id AS peak_id, p.name AS peak_name, p.altitude AS peak_altitude
      FROM peak_status ps
      INNER JOIN peaks p ON p.id = ps.peak_id
      WHERE ps.user_id = ? AND ps.${flagColumn} = 1
      ORDER BY ps.updated_at DESC, p.name ASC
      LIMIT ${safeLimit}
    `;

    const [rows] = await pool.execute(sql, [userId]);
    return rows.map((row) => ({
      peakId: Number(row.peak_id),
      peakName: row.peak_name,
      peakAltitude: Number(row.peak_altitude),
    }));
  },

  // Comarques associades a un conjunt de cims en una sola query (evita N+1).
  // Retorna Map<peakId, string[]> per assignació directa al consumidor.
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

module.exports = StatsModel;
