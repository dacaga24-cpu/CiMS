const PeakStatusModel = require('../models/peakStatusModel');

// Aquest servei centralitza el càlcul de les estadístiques personals de
// l'usuari. La pantalla d'estadístiques només necessita un sol endpoint per
// obtenir totes les xifres rellevants, així que aquí es combinen les dades
// crues de la base de dades en un objecte de resum llest per ser consumit.
//
// El càlcul es fa en memòria a partir dels estats personals de l'usuari
// perquè la mida d'aquesta col·lecció és sempre petita (un registre per cim
// que l'usuari ha tocat). Si en el futur el volum creix, es pot moure el
// càlcul a una query SQL agregada sense canviar el contracte de l'API.
const StatsService = {

  // Retorna el resum bàsic de progrés de l'usuari autenticat: nombre de cims
  // assolits, objectius actius i preferits. Si l'usuari encara no ha
  // interaccionat amb cap cim, els tres comptadors són zero (mai null), per
  // simplificar el consum des del frontend.
  async getUserStats(userId) {
    const statuses = await PeakStatusModel.findAllByUserId(userId);
    return computeProgressSummary(statuses);
  },
};

// Aquesta funció calcula els tres comptadors a partir de la llista d'estats.
// Es manté privada al mòdul perquè és un detall d'implementació; si en el
// futur s'enriqueix la resposta amb noves estadístiques, només cal estendre
// aquesta funció sense tocar la capa de servei ni el controlador.
function computeProgressSummary(statuses) {
  let completedPeaks = 0;
  let activeTargets = 0;
  let favorites = 0;

  // Es fa un sol recorregut perquè cada estat ja porta tots els flags i
  // així s'evita iterar tres vegades la mateixa llista.
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

module.exports = StatsService;
