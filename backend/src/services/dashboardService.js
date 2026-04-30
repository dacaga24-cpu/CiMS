const StatsModel = require('../models/statsModel');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Quants cims es retornen a les llistes de "pending" i "favorites" del
// dashboard. La pantalla d'inici només n'ensenya un resum compacte, així que
// cinc és suficient per donar context sense fer la resposta gran.
const DASHBOARD_LIST_LIMIT = 5;

// Mateix horitzó que utilitza /api/stats per a la sèrie mensual, perquè el
// gràfic del dashboard reflecteixi exactament el mateix període que la
// pantalla d'estadístiques i no calgui explicar a l'usuari per què veu
// dues finestres temporals diferents.
const MONTHLY_ASCENTS_WINDOW = 12;

// Configuració del repte fix dels 100 cims. Es manté com a constants aquí
// perquè és l'únic repte conegut a aquest endpoint; si en el futur hi ha
// reptes configurables per usuari, s'haurien de moure a la base de dades.
const CHALLENGE_TARGET_PEAKS = 100;
const CHALLENGE_TITLE = '100 Cims';

// Aquest servei composa el resum del dashboard a partir dels models existents.
// La pantalla d'inici fa una sola crida a /api/dashboard i rep totes les dades
// que necessita: el progrés del repte, els cims marcats com a objectius,
// els marcats com a preferits i la sèrie mensual d'ascensions.
//
// La separació respecte a statsService és intencional: el dashboard mostra
// "què tens per fer ara" (llistes accionables) mentre que /api/stats mostra
// "què has fet a la teva vida" (resum històric). Compartir el mateix endpoint
// faria que les dues pantalles haguessin de descartar dades que no necessiten.
const DashboardService = {

  // Retorna l'objecte complet que la pantalla del dashboard consumeix.
  // Les diferents fonts es consulten en paral·lel amb Promise.all per
  // minimitzar la latència total de la resposta. Les comarques associades
  // als cims llistats es resolen en una segona query batch per evitar el
  // patró N+1 amb peak_regions.
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

    return {
      challenge: composeChallenge(challengeRaw),
      pendingPeaks: enrichListWithRegions(pendingPeaksRaw, regionsByPeakId),
      favoritePeaks: enrichListWithRegions(favoritePeaksRaw, regionsByPeakId),
      monthlyAscents: fillMissingMonths(monthlyAscentsRaw, MONTHLY_ASCENTS_WINDOW),
    };
  },
};

// Aquesta funció converteix la dada bruta del repte en l'estructura que la
// pantalla del dashboard espera. Afegeix el títol estàtic, calcula el camp
// "remaining" (objectiu menys progrés) i el percentatge entre 0 i 100 perquè
// el frontend pugui pintar la barra de progrés sense haver de fer aquests
// càlculs per la seva banda. Es manté windowStart/windowEnd per si la UI vol
// indicar el període rolling al qual fa referència el repte.
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

// Aquesta funció associa a cada cim les seves comarques a partir del Map
// que retorna StatsModel.getRegionsForPeaks. Si un cim no té comarques
// resoltes, es retorna un array buit per mantenir un format de resposta
// consistent que el frontend pot consumir sense comprovar nulls.
function enrichListWithRegions(peaks, regionsByPeakId) {
  return peaks.map((peak) => ({
    ...peak,
    regions: regionsByPeakId.get(peak.peakId) || [],
  }));
}

module.exports = DashboardService;
