const PeakStatusModel = require('../models/peakStatusModel');
const AscentModel = require('../models/ascentModel');
const StatsModel = require('../models/statsModel');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Defineix quants mesos inclou la sèrie mensual d’ascensions.
// Aquest valor manté estable el contracte que consumeix el frontend.
const MONTHLY_ASCENTS_WINDOW = 12;

// Defineix quantes ascensions recents es retornen.
// Manté compatibilitat amb altres fluxos que encara poden utilitzar aquest camp.
const RECENT_ASCENTS_LIMIT = 5;

// Defineix quants cims formen el rànquing principal.
// Permet mostrar els cims més repetits sense carregar dades innecessàries.
const TOP_ASCENDED_PEAKS_LIMIT = 3;

// Defineix el rang temporal per defecte de les mètriques variables.
// L’últim any dona una lectura equilibrada entre activitat recent i progrés acumulat.
const DEFAULT_STATS_RANGE = 'year';

// Aquest servei centralitza el càlcul de les estadístiques personals.
// Combina estats, ascensions i dades agregades per retornar un resum preparat per al frontend.
const StatsService = {

  // Retorna el resum complet de progrés de l’usuari autenticat.
  // Inclou comptadors, metres acumulats, rànquings, gràfiques, repte i ratxes mensuals.
  async getUserStats(userId, range = DEFAULT_STATS_RANGE) {
    const selectedRange = normalizeStatsRange(range);

    const [
      statuses,
      ascents,
      highestCompletedAltitude,
      totalAltitudeMeters,
      totalAltitudeMetersAllTime,
      topAscendedPeaksRaw,
      monthlyAscentsRaw,
      monthlyActivityRaw,
      challengeProgress,
      recentAscentsRaw,
    ] = await Promise.all([
      PeakStatusModel.findAllByUserId(userId),
      AscentModel.findAllByUserId(userId),
      StatsModel.getHighestCompletedAltitude(userId),
      StatsModel.getTotalAltitudeMeters(userId, selectedRange),
      StatsModel.getTotalAltitudeMeters(userId, 'total'),
      StatsModel.getTopAscendedPeaks(userId, TOP_ASCENDED_PEAKS_LIMIT),
      StatsModel.getMonthlyAscentsRaw(userId, MONTHLY_ASCENTS_WINDOW),
      StatsModel.getMonthlyActivityRaw(userId),
      StatsModel.getChallengeProgress(userId),
      StatsModel.getRecentAscentsRaw(userId, RECENT_ASCENTS_LIMIT),
    ]);

    // Aquesta consulta recupera les comarques dels cims destacats en una sola operació.
    // Evita fer una petició individual per cada cim.
    const peakIdsNeedingRegions = collectPeakIdsForRegions(
      topAscendedPeaksRaw,
      recentAscentsRaw,
    );

    const regionsByPeakId = await StatsModel.getRegionsForPeaks(
      peakIdsNeedingRegions,
    );

    const topAscendedPeaks = topAscendedPeaksRaw.map((peak) =>
      enrichWithRegions(peak, regionsByPeakId),
    );

    return {
      ...computeProgressSummary(statuses),
      ...computeAscentMetrics(ascents),
      selectedRange,
      highestCompletedAltitude,
      totalAltitudeMeters,
      totalAltitudeMetersAllTime,
      topAscendedPeaks,
      mostAscendedPeak: topAscendedPeaks[0] || null,
      monthlyAscents: fillMissingMonths(
        monthlyAscentsRaw,
        MONTHLY_ASCENTS_WINDOW,
      ),
      monthlyStreak: computeMonthlyStreak(monthlyActivityRaw),
      challengeProgress,
      recentAscents: recentAscentsRaw.map((ascent) =>
        enrichWithRegions(ascent, regionsByPeakId),
      ),
    };
  },
};

// Calcula els comptadors principals a partir dels estats personals.
// Resumeix quants cims estan completats, marcats com a objectiu o guardats com a favorits.
function computeProgressSummary(statuses) {
  let completedPeaks = 0;
  let activeTargets = 0;
  let favorites = 0;

  for (const status of statuses) {
    if (status.is_completed === 1) {
      completedPeaks += 1;
    }

    if (status.is_target === 1) {
      activeTargets += 1;
    }

    if (status.is_favorite === 1) {
      favorites += 1;
    }
  }

  return { completedPeaks, activeTargets, favorites };
}

// Calcula les mètriques bàsiques de l’historial d’ascensions.
// Només compta ascensions amb data perquè representen activitat cronològica real.
function computeAscentMetrics(ascents) {
  const datedAscents = ascents.filter((ascent) => ascent.ascent_date !== null);

  if (datedAscents.length === 0) {
    return { totalAscents: 0, uniquePeaksAscended: 0 };
  }

  const uniquePeakIds = new Set();

  for (const ascent of datedAscents) {
    uniquePeakIds.add(ascent.peak_id);
  }

  return {
    totalAscents: datedAscents.length,
    uniquePeaksAscended: uniquePeakIds.size,
  };
}

// Recull els identificadors dels cims que necessiten comarques.
// Centralitza aquesta preparació per enriquir diferents blocs de la resposta.
function collectPeakIdsForRegions(topAscendedPeaks, recentAscents) {
  const peakIds = new Set();

  for (const peak of topAscendedPeaks) {
    peakIds.add(peak.peakId);
  }

  for (const ascent of recentAscents) {
    peakIds.add(ascent.peakId);
  }

  return Array.from(peakIds);
}

// Afegeix les comarques a un objecte relacionat amb un cim.
// Si no hi ha objecte, retorna null per mantenir el contracte del frontend.
function enrichWithRegions(peakObject, regionsByPeakId) {
  if (peakObject === null) {
    return null;
  }

  return {
    ...peakObject,
    regions: regionsByPeakId.get(peakObject.peakId) || [],
  };
}

// Calcula la ratxa mensual actual i la millor ratxa històrica.
// Una ratxa compta mesos consecutius amb almenys una ascensió datada.
function computeMonthlyStreak(monthlyActivityRaw) {
  if (!Array.isArray(monthlyActivityRaw) || monthlyActivityRaw.length === 0) {
    return {
      current: 0,
      best: 0,
    };
  }

  const activeMonths = new Set(
    monthlyActivityRaw.map((item) => monthKey(item.year, item.month)),
  );

  let best = 0;
  let currentRun = 0;
  let previousKey = null;

  for (const item of monthlyActivityRaw) {
    const key = monthKey(item.year, item.month);

    if (previousKey === null || key === previousKey + 1) {
      currentRun += 1;
    } else {
      currentRun = 1;
    }

    best = Math.max(best, currentRun);
    previousKey = key;
  }

  const today = new Date();
  let cursorYear = today.getFullYear();
  let cursorMonth = today.getMonth() + 1;
  let current = 0;

  while (activeMonths.has(monthKey(cursorYear, cursorMonth))) {
    current += 1;

    cursorMonth -= 1;
    if (cursorMonth === 0) {
      cursorMonth = 12;
      cursorYear -= 1;
    }
  }

  return {
    current,
    best,
  };
}

// Converteix any i mes en una clau numèrica correlativa.
// Això permet detectar mesos consecutius sense dependre de dates completes.
function monthKey(year, month) {
  return year * 12 + month;
}

// Normalitza el rang temporal rebut pel servei.
// Si arriba un valor desconegut, s’aplica el rang per defecte.
function normalizeStatsRange(range) {
  const allowedRanges = ['month', 'quarter', 'six_months', 'year', 'total'];

  if (allowedRanges.includes(range)) {
    return range;
  }

  return DEFAULT_STATS_RANGE;
}

module.exports = StatsService;