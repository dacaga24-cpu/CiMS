const MonthlyChallengeModel = require('../models/monthlyChallengeModel');
const {
  getCurrentMadridYearMonth,
  getCurrentMadridDateTimeString,
  getMonthBoundaryStrings,
  getMonthDateBoundaryStrings,
  getPreviousYearMonth,
} = require('../utils/madridTime');

// Catàleg dels tipus de repte. Cada entrada exposa exactament tres targets
// creixents perquè recomputeProgress assumeix tres nivells fixos; canviar
// el nombre de targets trencaria el càlcul de current_level.
const CHALLENGE_TYPES = {
  peaks_completed: {
    targets: [2, 4, 6],
    counter: (userId, startDate, endDate) =>
      MonthlyChallengeModel.countDistinctPeaksInMonth(userId, startDate, endDate),
  },
  distinct_regions: {
    targets: [2, 3, 5],
    counter: (userId, startDate, endDate) =>
      MonthlyChallengeModel.countDistinctRegionsInMonth(userId, startDate, endDate),
  },
};

const ALL_TYPES = Object.keys(CHALLENGE_TYPES);

// Lògica del repte mensual. El recompute es fa des de zero comptant la taula
// ascents (no incrementant un comptador), així el progrés sempre reflecteix
// la realitat encara que es modifiquin ascensions antigues.
const MonthlyChallengeService = {

  // Repte actiu del mes en curs amb el progrés de l'usuari. La plantilla es
  // genera "lazy" si encara no existeix; el progrés zero no crea fila a la BD.
  async getCurrentChallengeForUser(userId) {
    const { year, month } = getCurrentMadridYearMonth();
    const challenge = await ensureMonthlyChallenge(year, month);
    const progress = await MonthlyChallengeModel.findProgress(userId, challenge.id);
    return composeChallengeResponse(challenge, progress);
  },

  // Recalcula el progrés per al mes d'una ascent_date. Si la data no és del
  // mes en curs (Madrid) no fa res: els reptes passats estan tancats.
  async recomputeForUser(userId, ascentDate) {
    if (!ascentDate) {
      return;
    }
    const [year, month] = parseYearMonth(ascentDate);
    const current = getCurrentMadridYearMonth();
    if (year !== current.year || month !== current.month) {
      return;
    }
    await recomputeProgress(userId, year, month);
  },

  // Recalcula el progrés del mes en curs sense necessitar cap data concreta.
  // S'usa des d'ascentService.update quan la data antiga o la nova podrien
  // estar dins del mes actual.
  async recomputeCurrentMonthForUser(userId) {
    const { year, month } = getCurrentMadridYearMonth();
    await recomputeProgress(userId, year, month);
  },
};

// Garanteix que la plantilla del mes existeix. Una carrera entre dues
// peticions concurrents es resol amb el UNIQUE de l'schema: la segona
// rep ER_DUP_ENTRY i fa SELECT del registre que ha guanyat la cursa.
async function ensureMonthlyChallenge(year, month) {
  const existing = await MonthlyChallengeModel.findByPeriod(year, month);
  if (existing) {
    return existing;
  }

  const type = await pickChallengeType(year, month);
  const targets = CHALLENGE_TYPES[type].targets;
  const { startsAt, endsAt } = getMonthBoundaryStrings(year, month);

  try {
    await MonthlyChallengeModel.create({
      year, month, type,
      target1: targets[0],
      target2: targets[1],
      target3: targets[2],
      startsAt, endsAt,
    });
  } catch (err) {
    if (!err || err.code !== 'ER_DUP_ENTRY') {
      throw err;
    }
    // Una altra petició ha creat la plantilla; continuem i la recuperem.
  }

  const stored = await MonthlyChallengeModel.findByPeriod(year, month);
  if (!stored) {
    // Defensiu: ER_DUP_ENTRY però el SELECT posterior no la troba indica un
    // rollback rival o un problema de replicació, en tots dos casos estat
    // inconsistent que demana logs.
    const error = new Error('Could not create monthly challenge template');
    error.statusCode = 500;
    throw error;
  }
  return stored;
}

// Tipus de repte aleatori. Si hi ha més d'un tipus i el mes anterior ja en
// tenia, exclou aquell tipus per donar variació entre mesos consecutius.
async function pickChallengeType(year, month) {
  const previous = getPreviousYearMonth(year, month);
  const previousChallenge = await MonthlyChallengeModel.findByPeriod(
    previous.year, previous.month
  );
  const candidates = previousChallenge && ALL_TYPES.length > 1
    ? ALL_TYPES.filter((type) => type !== previousChallenge.type)
    : ALL_TYPES;
  const index = Math.floor(Math.random() * candidates.length);
  return candidates[index];
}

// Recalcula el progrés per a la plantilla d'un mes. La plantilla es garanteix
// aquí mateix, així una primera ascensió en mes nou genera plantilla i progrés
// en una sola crida.
//
// Decisió de producte als segells level_X_completed_at: si el progrés cau per
// sota del llindar (ascensió eliminada), el segell torna a NULL i el nivell
// es desbloqueja.
async function recomputeProgress(userId, year, month) {
  const challenge = await ensureMonthlyChallenge(year, month);
  const counter = CHALLENGE_TYPES[challenge.type].counter;
  const { startDate, endDate } = getMonthDateBoundaryStrings(year, month);
  const realProgress = await counter(userId, startDate, endDate);

  const targets = [challenge.target_1, challenge.target_2, challenge.target_3];

  // El progrés es capa al llindar màxim. Sense aquest cap, un usuari que en
  // fes més veuria "8 de 6" a la UI un cop completat el repte.
  const currentProgress = Math.min(realProgress, targets[targets.length - 1]);

  const existing = await MonthlyChallengeModel.findProgress(userId, challenge.id);
  const now = getCurrentMadridDateTimeString();

  const stamps = [
    existing?.level_1_completed_at ?? null,
    existing?.level_2_completed_at ?? null,
    existing?.level_3_completed_at ?? null,
  ];
  const finalStamps = targets.map((target, index) =>
    currentProgress >= target ? (stamps[index] ?? now) : null
  );

  let currentLevel = 0;
  for (const target of targets) {
    if (currentProgress >= target) {
      currentLevel += 1;
    }
  }

  await MonthlyChallengeModel.upsertProgress({
    userId,
    monthlyChallengeId: challenge.id,
    currentProgress,
    currentLevel,
    level1CompletedAt: finalStamps[0],
    level2CompletedAt: finalStamps[1],
    level3CompletedAt: finalStamps[2],
  });
}

// Composa la resposta JSON. Sempre torna tots els camps amb valors coherents
// encara que l'usuari no tingui fila de progrés, perquè el frontend no hagi
// de fer comprovacions defensives sobre absències.
function composeChallengeResponse(challenge, progress) {
  const targets = [challenge.target_1, challenge.target_2, challenge.target_3];
  const currentProgress = progress?.current_progress ?? 0;
  const currentLevel = progress?.current_level ?? 0;
  return {
    id: challenge.id,
    year: challenge.year,
    month: challenge.month,
    type: challenge.type,
    targets,
    startsAt: challenge.starts_at,
    endsAt: challenge.ends_at,
    currentProgress,
    currentLevel,
    isFullyCompleted: currentLevel >= targets.length,
    levelCompletedAt: {
      level1: progress?.level_1_completed_at ?? null,
      level2: progress?.level_2_completed_at ?? null,
      level3: progress?.level_3_completed_at ?? null,
    },
  };
}

// Extreu any i mes d'una cadena 'YYYY-MM-DD'. El format el valida prèviament
// requireIsoDate / parseOptionalIsoDate al servei cridant.
function parseYearMonth(ascentDate) {
  const [yearStr, monthStr] = String(ascentDate).split('-');
  return [Number(yearStr), Number(monthStr)];
}

module.exports = MonthlyChallengeService;
