const StatsModel = require('../models/statsModel');
const { fillMissingMonths } = require('../utils/statsHelpers');

const DASHBOARD_LIST_LIMIT = 5;

// Mateix horitzó que /api/stats per coherència entre la sèrie del dashboard
// i la de la pantalla d'estadístiques.
const MONTHLY_ASCENTS_WINDOW = 12;

// Configuració del repte fix dels 100 cims. Si en el futur hi ha reptes
// configurables per usuari, mouríem aquestes constants a la BD.
const CHALLENGE_TARGET_PEAKS = 100;
const CHALLENGE_TITLE = '100 Cims';

// Composa el resum del dashboard (repte, objectius, preferits, sèrie mensual).
// Separat de statsService a propòsit: el dashboard mostra "què tens per fer
// ara" mentre que /api/stats mostra "què has fet" — compartir endpoint
// obligaria les dues pantalles a descartar dades.
const DashboardService = {

  // Objecte complet que consumeix el dashboard. Promise.all paral·lelitza les
  // fonts; les comarques es resolen en una segona query batch (evita N+1).
  async getDashboard(userId) {
    const [
      challengeRaw,
      pendingPeaksRaw,
      favoritePeaksRaw,
      monthlyAscentsRaw,
    ] = await Promise.all([
      StatsModel.getChallengeProgress(userId),
      StatsModel.findFlaggedPeaks(userId, 'is_target', DASHBOARD_LIST_LIMIT),
      StatsModel.findFlaggedPeaks(userId, 'is_favorite', DASHBOARD_LIST_LIMIT),
      StatsModel.getMonthlyAscentsRaw(userId, MONTHLY_ASCENTS_WINDOW),
    ]);

    const peakIdsForRegions = new Set();
    for (const peak of pendingPeaksRaw) peakIdsForRegions.add(peak.peakId);
    for (const peak of favoritePeaksRaw) peakIdsForRegions.add(peak.peakId);

    const regionsByPeakId = peakIdsForRegions.size > 0
      ? await StatsModel.getRegionsForPeaks([...peakIdsForRegions])
      : new Map();

    const monthlyAscents = fillMissingMonths(
      monthlyAscentsRaw,
      MONTHLY_ASCENTS_WINDOW
    );

    return {
      challengeProgress: composeChallenge(challengeRaw),
      pendingPeaks: enrichListWithRegions(pendingPeaksRaw, regionsByPeakId),
      favoritePeaks: enrichListWithRegions(favoritePeaksRaw, regionsByPeakId),
      monthlyAscents,
    };
  },
};

// Converteix la dada bruta del repte en l'estructura que espera el dashboard
// (afegeix títol, remaining i percentage perquè el frontend pinti la barra
// sense haver de calcular).
function composeChallenge(raw) {
  const completed = Math.min(raw.completed, CHALLENGE_TARGET_PEAKS);
  const remaining = Math.max(CHALLENGE_TARGET_PEAKS - completed, 0);
  const percentage = CHALLENGE_TARGET_PEAKS === 0
    ? 0
    : Math.min(Math.round((completed / CHALLENGE_TARGET_PEAKS) * 100), 100);

  return {
    title: CHALLENGE_TITLE,
    completed,
    target: CHALLENGE_TARGET_PEAKS,
    remaining,
    percentage,
    windowStart: raw.windowStart,
    windowEnd: raw.windowEnd,
  };
}

// Associa a cada cim les seves comarques. Array buit si no en té resoltes,
// per mantenir un format consistent al frontend.
function enrichListWithRegions(peaks, regionsByPeakId) {
  return peaks.map((peak) => ({
    ...peak,
    regions: regionsByPeakId.get(peak.peakId) || [],
  }));
}

module.exports = DashboardService;
