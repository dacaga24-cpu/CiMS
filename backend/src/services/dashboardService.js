const StatsModel = require('../models/statsModel');
const AscentPhotoModel = require('../models/ascentPhotoModel');
const StorageService = require('./storageService');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Defineix quants cims es mostren a les llistes resum del dashboard.
// Aquest valor manté la pantalla lleugera i evita retornar més dades de les
// necessàries per a una vista inicial.
const DASHBOARD_LIST_LIMIT = 5;

// Defineix quants mesos es mostren a la sèrie mensual del dashboard.
// Es manté el mateix període que a la pantalla d'estadístiques per donar una
// lectura coherent del progrés de l'usuari.
const MONTHLY_ASCENTS_WINDOW = 12;

// Defineix quantes fotos recents es mostren al carrusel del dashboard.
// Aquest bloc és només un resum visual; la galeria completa tindrà el seu
// propi endpoint i podrà carregar més imatges.
const RECENT_PHOTOS_LIMIT = 12;

// Defineix la configuració del repte principal dels 100 cims.
// De moment és un repte fix de l'aplicació; si més endavant hi ha reptes
// personalitzats, aquesta informació s'hauria de moure a la base de dades.
const CHALLENGE_TARGET_PEAKS = 100;
const CHALLENGE_TITLE = '100 Cims';

// Aquest servei construeix les dades que necessita la pantalla principal.
// Agrupa el progrés del repte, els cims pendents, els favorits, l'activitat
// mensual i les fotos recents de les ascensions de l'usuari autenticat.
const DashboardService = {

  // Retorna el resum complet del dashboard per a un usuari concret.
  // Les dades principals es consulten en paral·lel per reduir el temps de
  // resposta i després s'enriqueixen només amb la informació necessària per
  // pintar la pantalla.
  async getDashboard(userId) {
    const [
      challengeRaw,
      pendingPeaksRaw,
      favoritePeaksRaw,
      monthlyAscentsRaw,
      recentPhotosRaw,
    ] = await Promise.all([
      StatsModel.getChallengeProgress(userId),
      StatsModel.findFlaggedPeaks(userId, 'is_target', DASHBOARD_LIST_LIMIT),
      StatsModel.findFlaggedPeaks(userId, 'is_favorite', DASHBOARD_LIST_LIMIT),
      StatsModel.getMonthlyAscentsRaw(userId, MONTHLY_ASCENTS_WINDOW),
      AscentPhotoModel.findRecentRepresentativeByUserId(
        userId,
        RECENT_PHOTOS_LIMIT
      ),
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
      recentPhotos: await enrichRecentPhotosWithDownloadUrls(recentPhotosRaw),
    };
  },
};

// Aquesta funció adapta la informació del repte al format que espera el
// frontend. Calcula el progrés restant i el percentatge perquè la interfície
// només hagi de mostrar les dades, no calcular-les.
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

// Aquesta funció afegeix les comarques corresponents a cada cim del resum.
// Si un cim no té comarques associades, retorna una llista buida per mantenir
// una resposta estable i fàcil de consumir des del frontend.
function enrichListWithRegions(peaks, regionsByPeakId) {
  return peaks.map((peak) => ({
    ...peak,
    regions: regionsByPeakId.get(peak.peakId) || [],
  }));
}

// Aquesta funció prepara les fotos recents perquè siguin visibles al dashboard.
// Cada foto rep una URL temporal de descàrrega, mantenint el bucket privat i
// retornant al frontend només l'accés necessari per mostrar la imatge.
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