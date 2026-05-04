const pool = require('../config/db');

// Aquest model agrupa l'accés a les dues taules del repte mensual:
// monthly_challenges (la plantilla global del mes) i monthly_challenge_progress
// (el progrés de cada usuari sobre aquesta plantilla). Es manté separat dels
// models de domini (ascents, peak_status) perquè la lògica de comptatge
// requereix joins agregats que només té sentit servir des d'aquest recurs.
//
// Tot el SQL filtra per (year, month) sobre ascent_date, perquè una ascensió
// compta per al repte del mes en què va passar realment, no en què es va
// registrar al sistema. Així una pujada antiga afegida tard no contamina el
// mes en curs.
const MonthlyChallengeModel = {

  // Retorna la plantilla del repte d'un mes concret, o null si encara no
  // s'ha generat. La unicitat per (year, month) està garantida a l'schema.
  // Les columnes `year` i `month` van entre cometes invertides perquè són
  // paraules reservades a MySQL i, encara que en la majoria de versions
  // funcionen sense escapar, deixar-ho explícit evita confusió amb les
  // funcions YEAR()/MONTH() que també apareixen en aquest mateix fitxer.
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

  // Crea la plantilla del repte d'un mes. La carrera entre dues peticions
  // simultànies que intentin crear la mateixa plantilla es resol amb el
  // UNIQUE (year, month) de l'schema: si dues insercions arriben alhora,
  // una guanya i l'altra rep ER_DUP_ENTRY, que aquí es propaga perquè el
  // servei pugui fer el SELECT del registre ja existent.
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

  // Retorna el progrés d'un usuari sobre una plantilla concreta. Si encara
  // no n'ha generat cap (l'usuari no ha tocat cap ascensió del mes), el
  // resultat és null i el servei tractarà aquest cas com a progrés zero.
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

  // Crea o actualitza la fila de progrés de l'usuari sobre una plantilla.
  // L'ON DUPLICATE KEY UPDATE aprofita el UNIQUE (user_id, monthly_challenge_id)
  // per fer l'upsert en una sola query. Tots els camps level_X_completed_at
  // poden ser NULL: si el progrés baixa per sota del llindar, el segell es
  // desbloqueja (decisió de producte: el progrés del mes pot oscil·lar).
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

  // Compta cims únics que un usuari ha completat dins d'un mes natural.
  // Es considera "completat" qualsevol cim amb com a mínim una ascensió
  // amb ascent_date dins del rang. Es compta DISTINCT peak_id perquè un
  // mateix cim pujat dues vegades el mateix mes només suma una unitat al
  // progrés del repte.
  //
  // El filtre s'expressa com a BETWEEN sobre ascent_date amb les dates de
  // primer i últim dia del mes ja calculades pel servei. Així la query
  // pot aprofitar idx_ascents_date, cosa que MONTH(ascent_date)=? no
  // permetria perquè la funció a sobre de la columna la fa no sargable.
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

  // Compta comarques úniques on un usuari ha completat com a mínim un cim
  // dins del mes natural. El JOIN amb peak_regions reflecteix que un cim
  // pot pertànyer a més d'una comarca, així que pujar un cim que toca dues
  // comarques compta dues comarques úniques per al repte.
  //
  // Mateix raonament que countDistinctPeaksInMonth: BETWEEN sobre ascent_date
  // amb les dates ja calculades al servei perquè la query sigui sargable.
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
