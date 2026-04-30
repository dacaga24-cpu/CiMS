const PeakStatusModel = require('../models/peakStatusModel');
const AscentModel = require('../models/ascentModel');
const StatsModel = require('../models/statsModel');
const { fillMissingMonths } = require('../utils/statsHelpers');

// Quants mesos d'historial inclou la sèrie monthlyAscents que serveix el
// gràfic de la pantalla d'estadístiques. Es manté com a constant perquè és
// el contracte que espera el frontend i un canvi requeriria coordinar-se
// amb la implementació de la vista.
const MONTHLY_ASCENTS_WINDOW = 12;

// Quantes ascensions recents s'inclouen a recentAscents. La pantalla mostra
// una llista compacta a la capçalera, així que cinc és suficient per donar
// context sense inflar la mida de la resposta.
const RECENT_ASCENTS_LIMIT = 5;

// Aquest servei centralitza el càlcul de les estadístiques personals de
// l'usuari. La pantalla d'estadístiques només necessita un sol endpoint per
// obtenir totes les xifres rellevants, així que aquí es combinen les dades
// crues de la base de dades en un objecte de resum llest per ser consumit.
//
// Les fonts de dades es consulten en paral·lel amb Promise.all perquè no
// depenen entre si i així es minimitza la latència total de la resposta.
// Les comarques associades als cims que apareixen a mostAscendedPeak i
// recentAscents es resolen en una segona query batch per evitar problemes
// de N+1 amb peak_regions.
const StatsService = {

  // Retorna el resum complet de progrés de l'usuari autenticat. Conté tres
  // seccions lògiques: comptadors d'estat (assolits/objectius/preferits),
  // mètriques d'ascensions (totals, cims únics, altitud acumulada, repte
  // rolling, gràfic mensual i activitat recent) i derivades creuades (cim
  // més pujat, altitud màxima assolida).
  //
  // Tots els camps tenen un valor coherent encara que l'usuari sigui nou:
  // els comptadors són zero, els objectes derivats són null i els arrays
  // mantenen la seva mida lògica (per exemple, monthlyAscents sempre té 12
  // entrades). Així el frontend no ha de fer comprovacions defensives sobre
  // l'absència de camps.
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

    // Una segona query batch resol les comarques de tots els cims que
    // apareixen a mostAscendedPeak i recentAscents, així s'enriqueixen
    // sense fer una crida per cim i sense duplicar files al SQL principal.
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

// Calcula els tres comptadors principals a partir dels estats personals.
// Es fa en un sol recorregut perquè cada estat ja porta tots els flags i
// així s'evita iterar tres vegades la mateixa col·lecció.
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

// Calcula les mètriques bàsiques derivades de l'historial d'ascensions:
// el total i el nombre de cims únics on l'usuari ha pujat. Un cim pujat
// diverses vegades es compta com a una sola entrada a uniquePeaksAscended,
// mentre que cada ascensió individual contribueix a totalAscents.
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

// Recull els peakIds que necessiten enriquiment de comarques. Es centralitza
// aquí perquè si en el futur s'afegeixen més camps amb cim associat, només
// cal incloure'ls en aquesta funció i la resta del flux funcionarà igual.
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

// Retorna una còpia de l'objecte amb la propietat regions afegida a partir
// del mapa de comarques. Si l'objecte d'entrada és null (cas on no hi ha cap
// cim a enriquir), es retorna null tal qual perquè el contracte és uniforme.
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
