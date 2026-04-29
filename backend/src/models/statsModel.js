const pool = require('../config/db');

// Aquest model agrupa les consultes agregades específiques per a la pantalla
// d'estadístiques. Es manté separat dels models de domini (peakStatus, ascent)
// perquè aquí hi viuen JOINs i agregacions que no tenen lloc en cap d'aquells
// recursos individuals i que servirien només a aquesta vista.
const StatsModel = {

  // Retorna l'altitud màxima entre els cims que l'usuari ha marcat com a
  // assolits. Es resol amb una sola query agregada per evitar carregar la
  // taula sencera de peaks al servidor d'aplicació. Si l'usuari encara no
  // ha completat cap cim, retorna null perquè el servei pugui distingir
  // aquest cas i no enviar un zero ambigu al client.
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

  // Retorna la suma d'altitud acumulada per totes les ascensions de l'usuari.
  // Cada ascensió compta de manera independent, de manera que pujar tres
  // vegades al mateix cim suma tres vegades la seva altitud. Aquesta lectura
  // reflecteix l'esforç físic acumulat, que és el que fa servir la pantalla
  // d'estadístiques per indicar "metres totals escalats".
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

  // Retorna el cim que l'usuari ha pujat més vegades. En cas d'empat al
  // nombre d'ascensions, prioritza el de més altitud per oferir un resultat
  // determinístic i alhora informativament més significatiu. Retorna null
  // si l'usuari encara no ha registrat cap ascensió.
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

  // Retorna el nombre d'ascensions agrupades per any i mes. La query només
  // inclou els mesos amb activitat real; correspon al servei completar els
  // mesos sense ascensions amb count zero per garantir un array de mida fixa
  // al client (i així poder dibuixar el gràfic sense forats lògics).
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

  // Calcula el progrés del repte rolling de 100 cims únics. La finestra
  // sempre acaba a la data de l'última ascensió de l'usuari i s'estén un any
  // cap enrere des d'aquell punt. Aquest disseny garanteix que cada nova
  // ascensió desplaça la finestra cap endavant, de manera que l'usuari sempre
  // pot completar el repte si segueix pujant cims diferents.
  //
  // El comptador són cims únics (un cim pujat diverses vegades dins la
  // finestra es compta una sola vegada) perquè l'enunciat del repte és
  // explícitament "100 cims diferents", no "100 ascensions".
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

  // Retorna les últimes ascensions de l'usuari amb informació enriquida del
  // cim associat (nom i altitud). Les comarques no s'inclouen aquí perquè es
  // resolen en una segona query batch al servei per evitar files duplicades
  // quan un cim té diverses comarques associades.
  async getRecentAscentsRaw(userId, limit) {
    // El límit s'interpola directament perquè mysql2 no suporta paràmetres
    // preparats per a LIMIT en totes les versions, però el valor sempre és
    // un enter validat al servei i mai prové de l'usuari.
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

  // Retorna les comarques associades a un conjunt de cims en una sola query.
  // L'ús habitual és cridar-lo amb els peakIds que el servei ja sap que
  // necessita (els del cim més pujat i els de les ascensions recents) per
  // evitar problemes de N+1.
  //
  // Retorna un Map<peakId, string[]> perquè els consumidors puguin assignar
  // les comarques a cada cim sense buscar manualment dins una llista plana.
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
