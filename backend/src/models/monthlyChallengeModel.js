const pool = require('../config/db');

// Aquest model centralitza les dades del repte mensual.
// Gestiona la plantilla global del mes i el progrés personal de cada usuari.
const MonthlyChallengeModel = {

  // Retorna la plantilla del repte d’un mes concret.
  // Si encara no existeix, retorna null perquè el servei pugui crear-la o tractar el cas.
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

  // Crea la plantilla del repte mensual.
  // Defineix el període, el tipus de repte i els objectius que haurà d’assolir l’usuari.
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

  // Retorna el progrés d’un usuari dins d’un repte mensual.
  // Si no hi ha cap registre, el servei podrà interpretar-ho com a progrés inicial.
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

  // Crea o actualitza el progrés d’un usuari dins d’un repte mensual.
  // Manté en una sola operació el progrés actual, el nivell assolit i les dates de completació.
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

  // Compta els cims únics que un usuari ha completat dins d’un mes.
  // Aquest valor serveix per calcular el progrés dels reptes basats en cims assolits.
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

  // Compta les comarques úniques on l’usuari ha completat cims durant el mes.
  // Aquest valor permet calcular reptes mensuals basats en diversitat territorial.
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