const PeakStatusModel = require('../models/peakStatusModel');
const AscentModel = require('../models/ascentModel');
const StatsModel = require('../models/statsModel');

// Aquest servei centralitza el càlcul de les estadístiques personals de
// l'usuari. La pantalla d'estadístiques només necessita un sol endpoint per
// obtenir totes les xifres rellevants, així que aquí es combinen les dades
// crues de la base de dades en un objecte de resum llest per ser consumit.
//
// Les fonts de dades (estats personals i ascensions) es consulten en paral·lel
// amb Promise.all perquè no depenen entre si i així es minimitza la latència
// total de la resposta.
const StatsService = {

  // Retorna el resum de progrés de l'usuari autenticat amb els tres
  // comptadors bàsics (cims assolits, objectius actius, preferits) i un
  // conjunt de mètriques addicionals derivades de l'historial d'ascensions
  // que la pantalla d'estadístiques pot mostrar com a indicadors complementaris.
  //
  // Si l'usuari encara no ha interaccionat amb cap cim, els comptadors són zero
  // (mai null) i les mètriques que requereixen dades inexistents són null
  // (lastAscent, highestCompletedAltitude). Aquesta distinció permet al
  // frontend mostrar "encara no tens ascensions" sense ambigüitat respecte
  // a "tens 0 ascensions" (que no és un cas real, però en altres mètriques
  // sí que ho podria ser).
  async getUserStats(userId) {
    const [statuses, ascents, highestCompletedAltitude] = await Promise.all([
      PeakStatusModel.findAllByUserId(userId),
      AscentModel.findAllByUserId(userId),
      StatsModel.getHighestCompletedAltitude(userId),
    ]);

    return {
      ...computeProgressSummary(statuses),
      ...computeAscentMetrics(ascents),
      highestCompletedAltitude,
    };
  },
};

// Aquesta funció calcula els tres comptadors principals a partir de la llista
// d'estats. Es fa un sol recorregut perquè cada estat ja porta tots els flags
// i així s'evita iterar tres vegades la mateixa col·lecció.
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

  return {
    completedPeaks,
    activeTargets,
    favorites,
  };
}

// Aquesta funció calcula les mètriques derivades de l'historial d'ascensions:
//   - totalAscents: nombre total d'ascensions registrades.
//   - uniquePeaksAscended: cims diferents on ha pujat (un cim pujat tres
//     vegades compta com a un de sol).
//   - lastAscent: la més recent (peakId i data) o null si no en té cap.
//
// El model retorna les ascensions ordenades per data descendent, així que la
// primera entrada de la llista és la més recent i no cal recalcular-ho.
function computeAscentMetrics(ascents) {
  if (ascents.length === 0) {
    return {
      totalAscents: 0,
      uniquePeaksAscended: 0,
      lastAscent: null,
    };
  }

  const uniquePeakIds = new Set();
  for (const ascent of ascents) {
    uniquePeakIds.add(ascent.peak_id);
  }

  const mostRecent = ascents[0];

  return {
    totalAscents: ascents.length,
    uniquePeaksAscended: uniquePeakIds.size,
    lastAscent: {
      peakId: mostRecent.peak_id,
      ascentDate: mostRecent.ascent_date,
    },
  };
}

module.exports = StatsService;
