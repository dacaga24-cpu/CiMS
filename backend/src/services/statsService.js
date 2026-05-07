const PeakStatusModel = require('../models/peakStatusModel');
const AscentModel = require('../models/ascentModel');
const StatsModel = require('../models/statsModel');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Mesos d'historial a la sèrie monthlyAscents. Constant perquè és el contracte
// que espera el frontend; canviar-lo requereix coordinar-se amb la vista.
const MONTHLY_ASCENTS_WINDOW = 12;

const RECENT_ASCENTS_LIMIT = 5;

// Resum d'estadístiques personals. La pantalla només crida un endpoint i
// rep totes les xifres preparades. Les fonts es consulten en paral·lel
// (Promise.all) per minimitzar latència.
const StatsService = {

  // Resum complet de progrés. Tots els camps tenen valor coherent encara
  // que l'usuari sigui nou (zeros, nulls, arrays de mida fixa) perquè el
  // frontend no hagi de fer comprovacions defensives.
  async getUserStats(userId) {
    const [
      statuses,
      ascents,
      highestCompletedAltitude,
      totalAltitudeMeters,
      mostAscendedPeak,
      monthlyAscentsRaw,
      challengeProgress,
      recentAscentsRaw,
    ] = await Promise.all([
      PeakStatusModel.findAllByUserId(userId),
      AscentModel.findAllByUserId(userId),
      StatsModel.getHighestCompletedAltitude(userId),
      StatsModel.getTotalAltitudeMeters(userId),
      StatsModel.getMostAscendedPeak(userId),
      StatsModel.getMonthlyAscentsRaw(userId, MONTHLY_ASCENTS_WINDOW),
      StatsModel.getChallengeProgress(userId),
      StatsModel.getRecentAscentsRaw(userId, RECENT_ASCENTS_LIMIT),
    ]);

    // Segona query batch per resoldre les comarques dels cims que apareixen
    // a mostAscendedPeak i recentAscents (evita N+1 i duplicació de files).
    const peakIdsNeedingRegions = collectPeakIdsForRegions(
      mostAscendedPeak,
      recentAscentsRaw,
    );
    const regionsByPeakId = await StatsModel.getRegionsForPeaks(peakIdsNeedingRegions);

    return {
      ...computeProgressSummary(statuses),
      ...computeAscentMetrics(ascents),
      highestCompletedAltitude,
      totalAltitudeMeters,
      mostAscendedPeak: enrichWithRegions(mostAscendedPeak, regionsByPeakId),
      monthlyAscents: fillMissingMonths(monthlyAscentsRaw, MONTHLY_ASCENTS_WINDOW),
      challengeProgress,
      recentAscents: recentAscentsRaw.map((ascent) =>
        enrichWithRegions(ascent, regionsByPeakId),
      ),
    };
  },
};

// Calcula els tres comptadors d'estats personals en un sol recorregut.
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

// Mètriques bàsiques de l'historial: total i cims únics. Un cim pujat
// diverses vegades és una sola entrada a uniquePeaksAscended.
function computeAscentMetrics(ascents) {
  if (ascents.length === 0) {
    return { totalAscents: 0, uniquePeaksAscended: 0 };
  }

  const uniquePeakIds = new Set();
  for (const ascent of ascents) {
    uniquePeakIds.add(ascent.peak_id);
  }

  return {
    totalAscents: ascents.length,
    uniquePeaksAscended: uniquePeakIds.size,
  };
}

// Recull els peakIds que necessiten enriquiment de comarques.
function collectPeakIdsForRegions(mostAscendedPeak, recentAscents) {
  const peakIds = new Set();
  if (mostAscendedPeak) {
    peakIds.add(mostAscendedPeak.peakId);
  }
  for (const ascent of recentAscents) {
    peakIds.add(ascent.peakId);
  }
  return Array.from(peakIds);
}

// Còpia de l'objecte amb regions afegides. null tal qual si l'entrada és
// null, per mantenir un contracte uniforme.
function enrichWithRegions(peakObject, regionsByPeakId) {
  if (peakObject === null) {
    return null;
  }
  return {
    ...peakObject,
    regions: regionsByPeakId.get(peakObject.peakId) || [],
  };
}

module.exports = StatsService;
