const MonthlyChallengeModel = require('../models/monthlyChallengeModel');
const {
  getCurrentMadridYearMonth,
  getCurrentMadridDateTimeString,
  getMonthBoundaryStrings,
  getMonthDateBoundaryStrings,
  getPreviousYearMonth,
} = require('../utils/madridTime');

// Aquest catàleg defineix els tipus de repte mensual disponibles.
// Cada tipus indica els objectius i la manera de calcular el progrés de l’usuari.
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

// Aquest servei centralitza la lògica del repte mensual.
// Permet consultar el repte actiu i recalcular el progrés quan canvien les ascensions.
const MonthlyChallengeService = {

  // Retorna el repte actiu del mes en curs per a un usuari.
  // Si encara no existeix la plantilla mensual, es crea abans de retornar la resposta.
  async getCurrentChallengeForUser(userId) {
    const { year, month } = getCurrentMadridYearMonth();
    const challenge = await ensureMonthlyChallenge(year, month);
    const progress = await MonthlyChallengeModel.findProgress(userId, challenge.id);
    return composeChallengeResponse(challenge, progress);
  },

  // Recalcula el progrés de l’usuari a partir de la data d’una ascensió.
  // Només afecta el repte vigent si la data pertany al mes actual.
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

  // Recalcula el progrés de l’usuari per al mes actual.
  // S’utilitza quan no cal dependre d’una data concreta per actualitzar el repte.
  async recomputeCurrentMonthForUser(userId) {
    const { year, month } = getCurrentMadridYearMonth();
    await recomputeProgress(userId, year, month);
  },
};

// Garanteix que existeixi la plantilla del repte mensual.
// Si no existeix, selecciona un tipus de repte i crea el registre corresponent.
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
    // Si una altra petició ha creat la plantilla al mateix temps, es recupera després amb normalitat.
  }

  const stored = await MonthlyChallengeModel.findByPeriod(year, month);
  if (!stored) {
    const error = new Error('Could not create monthly challenge template');
    error.statusCode = 500;
    throw error;
  }
  return stored;
}

// Tria el tipus de repte del mes.
// Si és possible, evita repetir el mateix tipus utilitzat el mes anterior.
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

// Recalcula el progrés d’un usuari per a un mes concret.
// El càlcul es fa a partir de les ascensions reals per mantenir el repte sincronitzat.
async function recomputeProgress(userId, year, month) {
  const challenge = await ensureMonthlyChallenge(year, month);
  const counter = CHALLENGE_TYPES[challenge.type].counter;
  const { startDate, endDate } = getMonthDateBoundaryStrings(year, month);
  const realProgress = await counter(userId, startDate, endDate);

  const targets = [challenge.target_1, challenge.target_2, challenge.target_3];

  // Aquest límit evita que el progrés mostrat superi l’objectiu màxim del repte.
  // Així la interfície manté una lectura clara quan el repte ja està completat.
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

// Composa la resposta del repte mensual per al frontend.
// Sempre retorna una estructura completa encara que l’usuari no tingui progrés registrat.
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

// Extreu l’any i el mes a partir d’una data d’ascensió.
// Permet saber quin repte mensual s’ha d’actualitzar.
function parseYearMonth(ascentDate) {
  const [yearStr, monthStr] = String(ascentDate).split('-');
  return [Number(yearStr), Number(monthStr)];
}

module.exports = MonthlyChallengeService;