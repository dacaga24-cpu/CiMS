const StatsModel = require('../models/statsModel');
const AscentPhotoModel = require('../models/ascentPhotoModel');
const StorageService = require('./storageService');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Defineix quants cims es mostren a les llistes resum del dashboard.
// Aquest valor manté la pantalla lleugera i evita retornar més dades de les necessàries.
const DASHBOARD_LIST_LIMIT = 5;

// Defineix quantes ascensions recents es mostren al dashboard.
// Aquest bloc resumeix l'activitat real de l'usuari i només inclou ascensions amb data.
const RECENT_ASCENTS_LIMIT = 5;

// Defineix quants mesos es mantenen al resum mensual.
// Es conserva per compatibilitat amb el contracte de dades del dashboard.
const MONTHLY_ASCENTS_WINDOW = 12;

// Defineix quantes fotos recents es mostren al carrusel del dashboard.
// Es retornen les últimes fotos reals, encara que pertanyin a una mateixa ascensió.
const RECENT_PHOTOS_LIMIT = 12;

// Defineix la configuració del repte principal dels 100 cims.
// Es manté a la resposta per compatibilitat amb el frontend i altres pantalles.
const CHALLENGE_TARGET_PEAKS = 100;
const CHALLENGE_TITLE = '100 Cims';

// Aquest servei construeix les dades que necessita la pantalla principal.
// Agrupa objectius, preferits, activitat recent, fotos recents i dades de compatibilitat.
const DashboardService = {
  // Retorna el resum complet del dashboard per a un usuari concret.
  // Les consultes independents s'executen en paral·lel i després s'enriqueixen amb comarques.
  async getDashboard(userId) {
    const [
      challengeRaw,
      pendingPeaksRaw,
      favoritePeaksRaw,
      monthlyAscentsRaw,
      recentAscentsRaw,
      recentPhotosRaw,
    ] = await Promise.all([
      StatsModel.getChallengeProgress(userId),
      StatsModel.findFlaggedPeaks(userId, 'is_target', DASHBOARD_LIST_LIMIT),
      StatsModel.findFlaggedPeaks(userId, 'is_favorite', DASHBOARD_LIST_LIMIT),
      StatsModel.getMonthlyAscentsRaw(userId, MONTHLY_ASCENTS_WINDOW),
      StatsModel.getRecentAscentsRaw(userId, RECENT_ASCENTS_LIMIT),
      AscentPhotoModel.findRecentByUserId(userId, RECENT_PHOTOS_LIMIT),
    ]);

    const peakIdsForRegions = new Set();

    for (const peak of pendingPeaksRaw) {
      peakIdsForRegions.add(peak.peakId);
    }

    for (const peak of favoritePeaksRaw) {
      peakIdsForRegions.add(peak.peakId);
    }

    for (const ascent of recentAscentsRaw) {
      peakIdsForRegions.add(ascent.peakId);
    }

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
      recentAscents: enrichListWithRegions(recentAscentsRaw, regionsByPeakId),
      recentPhotos: await enrichRecentPhotosWithDownloadUrls(recentPhotosRaw),
    };
  },
};

// Aquesta funció adapta la informació del repte al format que espera el frontend.
// Calcula el progrés restant i el percentatge a partir de les dades agregades.
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

// Aquesta funció afegeix les comarques corresponents a cada element amb peakId.
// S'utilitza tant per cims resumits com per ascensions recents.
function enrichListWithRegions(items, regionsByPeakId) {
  return items.map((item) => ({
    ...item,
    regions: regionsByPeakId.get(item.peakId) || [],
  }));
}

// Aquesta funció prepara les fotos recents perquè siguin visibles al dashboard.
// Cada foto rep una URL temporal de descàrrega sense fer públic el bucket.
async function enrichRecentPhotosWithDownloadUrls(photos) {
  return Promise.all(
    photos.map(async (photo) => {
      let downloadUrl = null;

      try {
        downloadUrl = await StorageService.generateSignedDownloadUrl(
          photo.storage_path
        );
      } catch (err) {
        console.error(
          `[dashboardPhotos] sign download URL failed (photoId=${photo.id} path=${photo.storage_path}):`,
          err
        );
      }

      return {
        id: photo.id,
        ascentId: photo.ascent_id,
        peakId: photo.peak_id,
        peakName: photo.peak_name,
        ascentDate: photo.ascent_date,
        storagePath: photo.storage_path,
        isPrimary: photo.is_primary === 1,
        downloadUrl,
        createdAt: photo.created_at,
      };
    })
  );
}

module.exports = DashboardService;