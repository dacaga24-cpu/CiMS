const pool = require('../config/db');

// Accés a monthly_challenges (plantilla global del mes) i
// monthly_challenge_progress (progrés de cada usuari sobre la plantilla).
//
// Tot el SQL filtra per (year, month) sobre ascent_date: una ascensió compta
// per al repte del mes en què va passar realment, no en què es va registrar.
const MonthlyChallengeModel = {

  // Plantilla del repte d'un mes, o null si encara no s'ha generat. Les
  // columnes `year` i `month` van entre cometes invertides perquè són paraules
  // reservades a MySQL i per no confondre-les amb les funcions YEAR()/MONTH().
  async findByPeriod(year, month) {
    const sql = `
      SELECT id, \`year\`, \`month\`, type, target_1, target_2, target_3,
             starts_at, ends_at, created_at, updated_at
      FROM monthly_challenges
      WHERE \`year\` = ? AND \`month\` = ?
      LIMIT 1
    `;
    const [rows] = await pool.execute(sql, [year, month]);
    return rows[0] || null;
  },

  // Crea la plantilla. Una carrera entre dues peticions es resol amb el
  // UNIQUE (year, month): una guanya, l'altra rep ER_DUP_ENTRY que es propaga
  // perquè el servei pugui fer SELECT del registre existent.
  async create({ year, month, type, target1, target2, target3, startsAt, endsAt }) {
    const sql = `
      INSERT INTO monthly_challenges
        (\`year\`, \`month\`, type, target_1, target_2, target_3, starts_at, ends_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const [result] = await pool.execute(sql, [
      year, month, type, target1, target2, target3, startsAt, endsAt,
    ]);
    return result.insertId;
  },

  // Progrés d'un usuari sobre una plantilla. null si encara no n'ha generat
  // cap (el servei tracta aquest cas com a progrés zero).
  async findProgress(userId, monthlyChallengeId) {
    const sql = `
      SELECT id, user_id, monthly_challenge_id, current_progress, current_level,
             level_1_completed_at, level_2_completed_at, level_3_completed_at,
             created_at, updated_at
      FROM monthly_challenge_progress
      WHERE user_id = ? AND monthly_challenge_id = ?
      LIMIT 1
    `;
    const [rows] = await pool.execute(sql, [userId, monthlyChallengeId]);
    return rows[0] || null;
  },

  // Upsert del progrés d'un usuari. Aprofita el UNIQUE per fer-ho en una
  // sola query. Tots els level_X_completed_at poden ser NULL: si el progrés
  // baixa per sota del llindar el segell es desbloqueja (decisió de producte).
  async upsertProgress({
    userId, monthlyChallengeId,
    currentProgress, currentLevel,
    level1CompletedAt, level2CompletedAt, level3CompletedAt,
  }) {
    const sql = `
      INSERT INTO monthly_challenge_progress
        (user_id, monthly_challenge_id, current_progress, current_level,
         level_1_completed_at, level_2_completed_at, level_3_completed_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        current_progress     = VALUES(current_progress),
        current_level        = VALUES(current_level),
        level_1_completed_at = VALUES(level_1_completed_at),
        level_2_completed_at = VALUES(level_2_completed_at),
        level_3_completed_at = VALUES(level_3_completed_at)
    `;
    await pool.execute(sql, [
      userId, monthlyChallengeId,
      currentProgress, currentLevel,
      level1CompletedAt, level2CompletedAt, level3CompletedAt,
    ]);
  },

  // Cims únics que un usuari ha completat dins d'un mes natural. DISTINCT
  // peak_id perquè un cim pujat dues vegades el mateix mes només suma una.
  //
  // BETWEEN sobre ascent_date amb dates ja calculades pel servei: així la
  // query aprofita idx_ascents_date, cosa que MONTH(ascent_date) no faria.
  async countDistinctPeaksInMonth(userId, monthStartDate, monthEndDate) {
    const sql = `
      SELECT COUNT(DISTINCT peak_id) AS total
      FROM ascents
      WHERE user_id = ?
        AND ascent_date BETWEEN ? AND ?
    `;
    const [rows] = await pool.execute(sql, [userId, monthStartDate, monthEndDate]);
    return Number(rows[0].total);
  },

  // Comarques úniques on un usuari ha completat com a mínim un cim dins del
  // mes. El JOIN amb peak_regions reflecteix que un cim pot pertànyer a més
  // d'una comarca, així pujar un cim que toca dues comarques compta dues.
  async countDistinctRegionsInMonth(userId, monthStartDate, monthEndDate) {
    const sql = `
      SELECT COUNT(DISTINCT pr.region_id) AS total
      FROM ascents a
      INNER JOIN peak_regions pr ON pr.peak_id = a.peak_id
      WHERE a.user_id = ?
        AND a.ascent_date BETWEEN ? AND ?
    `;
    const [rows] = await pool.execute(sql, [userId, monthStartDate, monthEndDate]);
    return Number(rows[0].total);
  },
};

module.exports = MonthlyChallengeModel;
