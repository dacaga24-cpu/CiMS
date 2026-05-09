const PeakStatusModel = require('../models/peakStatusModel');
const AscentModel = require('../models/ascentModel');
const StatsModel = require('../models/statsModel');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Defineix quants mesos inclou la sèrie mensual d'ascensions.
// Aquest valor forma part del contracte que consumeix el frontend.
const MONTHLY_ASCENTS_WINDOW = 12;

// Defineix quantes ascensions recents es retornen a la pantalla d'estadístiques.
// La llista és compacta perquè només ha de donar context de l'activitat recent.
const RECENT_ASCENTS_LIMIT = 5;

// Aquest servei centralitza el càlcul de les estadístiques personals de l'usuari.
// Combina estats de cims, ascensions i consultes agregades per retornar
// un únic resum funcional preparat per al frontend.
//
// Les ascensions sense data només serveixen per justificar que un cim està completat.
// No formen part de les mètriques cronològiques, totals d'ascensions,
// metres acumulats, gràfiques mensuals ni activitat recent.
const StatsService = {

  // Retorna el resum complet de progrés de l'usuari autenticat.
  // Inclou comptadors d'estat, mètriques d'ascensions datades,
  // gràfic mensual, repte, activitat recent i cims destacats.
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

    // Aquesta consulta batch recupera les comarques dels cims destacats
    // sense fer una petició individual per cada cim.
    const peakIdsNeedingRegions = collectPeakIdsForRegions(
      mostAscendedPeak,
      recentAscentsRaw,
    );

    const regionsByPeakId = await StatsModel.getRegionsForPeaks(
      peakIdsNeedingRegions,
    );

    return {
      ...computeProgressSummary(statuses),
      ...computeAscentMetrics(ascents),
      highestCompletedAltitude,
      totalAltitudeMeters,
      mostAscendedPeak: enrichWithRegions(mostAscendedPeak, regionsByPeakId),
      monthlyAscents: fillMissingMonths(
        monthlyAscentsRaw,
        MONTHLY_ASCENTS_WINDOW,
      ),
      challengeProgress,
      recentAscents: recentAscentsRaw.map((ascent) =>
        enrichWithRegions(ascent, regionsByPeakId),
      ),
    };
  },
};

// Calcula els tres comptadors principals a partir dels estats personals.
// El completat es basa en peak_status, que es manté sincronitzat amb les ascensions.
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

// Calcula les mètriques bàsiques de l'historial d'ascensions.
// Només compta ascensions amb data perquè representen activitat cronològica real.
// Les ascensions sense data completen el cim, però no sumen al total ni als cims únics pujats.
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
// Centralitza aquesta preparació perquè el servei pugui enriquir diferents blocs
// sense repetir lògica.
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

module.exports = StatsService;