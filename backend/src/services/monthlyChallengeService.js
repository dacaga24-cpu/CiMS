const MonthlyChallengeModel = require('../models/monthlyChallengeModel');
const {
  getCurrentMadridYearMonth,
  getCurrentMadridDateTimeString,
  getMonthBoundaryStrings,
  getMonthDateBoundaryStrings,
  getPreviousYearMonth,
} = require('../utils/madridTime');

// Catàleg dels tipus de repte disponibles. Cada entrada ha d'exposar
// exactament tres targets creixents perquè recomputeProgress assumeix
// tres nivells fixos i una entrada amb un nombre diferent de targets
// trencaria el càlcul de current_level i dels segells level_X_completed_at.
// El "counter" rep les fronteres del mes ja calculades pel servei i ha de
// retornar un nombre enter amb el progrés actual de l'usuari.
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

// Aquest servei centralitza la lògica del repte mensual. Exposa la lectura
// del repte actiu de l'usuari i ofereix dos punts d'entrada de recompute
// (per data concreta o per mes en curs sencer) que ascentService crida
// després de cada modificació d'ascensions.
//
// El recompute es fa des de zero comptant la taula ascents, no incrementant
// un comptador existent. Així el progrés sempre reflecteix la realitat
// encara que es modifiquin ascensions antigues, i no calen migracions si
// algun dia s'arregla un bug que hagi deixat el cache desincronitzat.
const MonthlyChallengeService = {

  // Retorna el repte actiu del mes en curs amb el progrés de l'usuari.
  // Si la plantilla encara no s'ha generat, es crea aquí (creació "lazy").
  // Si l'usuari encara no té cap fila de progrés, es retorna progrés zero
  // sense crear cap registre — només es crea quan l'usuari realment
  // contribueix al repte amb una ascensió.
  async getCurrentChallengeForUser(userId) {
    const { year, month } = getCurrentMadridYearMonth();
    const challenge = await ensureMonthlyChallenge(year, month);
    const progress = await MonthlyChallengeModel.findProgress(userId, challenge.id);
    return composeChallengeResponse(challenge, progress);
  },

  // Recalcula el progrés d'un usuari per al mes que correspongui a una
  // ascent_date. S'invoca des d'ascentService cada vegada que es crea,
  // s'edita o s'esborra una ascensió. Si la data no pertany al mes en curs
  // (Madrid) la crida no fa res, perquè els reptes de mesos passats estan
  // tancats i les ascensions futures no afecten cap repte vigent.
  //
  // Es passa l'ascentDate com a string 'YYYY-MM-DD' (és el format que
  // utilitza el model d'ascents). Acceptem null/undefined per simplificar
  // les crides des d'ascentService.update quan no es modifica la data.
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

  // Variant que recalcula el progrés de l'usuari per al mes en curs sense
  // necessitat de saber cap data concreta. S'utilitza des d'ascentService
  // quan es modifica una ascensió i la data antiga o la nova podrien estar
  // dins del mes actual: és més senzill demanar un recompute global del
  // mes en curs que no pas comprovar dues dates per separat.
  async recomputeCurrentMonthForUser(userId) {
    const { year, month } = getCurrentMadridYearMonth();
    await recomputeProgress(userId, year, month);
  },
};

// Garanteix que la plantilla del mes existeix. Si encara no s'ha creat,
// se selecciona aleatòriament un tipus (evitant repetir el del mes anterior
// si hi ha més d'un tipus disponible) i s'insereix. Una carrera entre dues
// peticions concurrents que intentin crear la mateixa plantilla es resol
// amb el UNIQUE de l'schema: la segona rebrà ER_DUP_ENTRY i farà un SELECT
// del registre que ja ha guanyat la cursa.
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
    // Una altra petició concurrent ha creat la plantilla. Continuem i la
    // recuperem amb el SELECT de sota perquè el resultat sigui consistent.
  }

  const stored = await MonthlyChallengeModel.findByPeriod(year, month);
  if (!stored) {
    // Defensiu: arribar aquí significaria que el create ha vist ER_DUP_ENTRY
    // (una altra petició havia inserit la plantilla) però el SELECT posterior
    // no la troba. Pot indicar un rollback de la transacció rival o un
    // problema de replicació; en tots dos casos és un estat inconsistent
    // que requereix logs per diagnosticar.
    const error = new Error('Could not create monthly challenge template');
    error.statusCode = 500;
    throw error;
  }
  return stored;
}

// Tria un tipus de repte aleatori. Si el mes anterior ja existia una
// plantilla i hi ha més d'un tipus disponible, exclou aquell tipus per
// donar variació entre mesos consecutius.
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

// Recalcula el progrés d'un usuari per a la plantilla del mes indicat.
// La plantilla es garanteix dins d'aquesta mateixa funció perquè el flux
// des d'ascentService no requereixi haver-ho fet abans, i així una primera
// ascensió en un mes nou genera plantilla i progrés en una sola crida.
//
// El càlcul dels segells level_X_completed_at segueix la decisió de
// producte: si el progrés actual supera el llindar, es manté el segell
// existent o s'estampa "ara" si encara no n'hi havia; si el progrés cau
// per sota del llindar (perquè s'ha eliminat alguna ascensió), el segell
// es torna a NULL i el nivell es desbloqueja.
async function recomputeProgress(userId, year, month) {
  const challenge = await ensureMonthlyChallenge(year, month);
  const counter = CHALLENGE_TYPES[challenge.type].counter;
  const { startDate, endDate } = getMonthDateBoundaryStrings(year, month);
  const currentProgress = await counter(userId, startDate, endDate);

  const existing = await MonthlyChallengeModel.findProgress(userId, challenge.id);
  const now = getCurrentMadridDateTimeString();

  const targets = [challenge.target_1, challenge.target_2, challenge.target_3];
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

// Composa la resposta JSON que rebrà el client. Sempre torna tots els
// camps amb un valor coherent encara que l'usuari no tingui fila de
// progrés (cas d'usuari que encara no ha pujat res aquest mes), perquè
// el frontend no hagi de fer comprovacions defensives sobre absències.
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

// Extreu any i mes a partir d'una cadena 'YYYY-MM-DD'. El format l'han
// validat prèviament els helpers requireIsoDate / parseOptionalIsoDate al
// servei cridant, així que un split senzill és suficient i evita instanciar
// un Date. Si en el futur s'invoca aquest servei des d'un nou camí, la
// validació de format ha de quedar garantida abans d'arribar aquí.
function parseYearMonth(ascentDate) {
  const [yearStr, monthStr] = String(ascentDate).split('-');
  return [Number(yearStr), Number(monthStr)];
}

module.exports = MonthlyChallengeService;
