const PeakModel = require('../models/peakModel');
const weatherProvider = require('./weatherProvider');
const { requireInteger, requireIsoDate } = require('../utils/validation');

// Aquest fitxer concentra la lògica meteorològica de CiMS. La seva funció
// és orquestrar dos rols complementaris: parlar amb el proveïdor (a
// través de weatherProvider) i mantenir una capa de cache que protegeixi
// la quota de Google. Els controllers consumeixen aquest mòdul sense
// conèixer ni el proveïdor ni la base de dades.

// El TTL per defecte (1 hora) equilibra frescor i quota de Google: una
// previsió de 7 dies canvia poc dins d'una hora i així evitem llançar
// crides repetides quan diversos usuaris obren el mateix cim. El valor
// és configurable per variable d'entorn perquè en producció es pugui
// estirar a 2-3 hores si la quota es queda curta sense haver de
// redesplegar codi.
const DEFAULT_CACHE_TTL_MS = 60 * 60 * 1000;

function getCacheTtlMs() {
  const fromEnv = Number(process.env.WEATHER_CACHE_TTL_MS);
  if (Number.isFinite(fromEnv) && fromEnv > 0) {
    return fromEnv;
  }
  return DEFAULT_CACHE_TTL_MS;
}

// Cache simple en memòria del procés. La complexitat d'un Redis o d'una
// taula weather_cache no es justifica per a l'MVP: amb una sola rèplica
// activa, aquest Map cobreix el cas habitual i evita afegir dependències
// noves. Si en el futur cal compartir cache entre rèpliques, la migració
// queda localitzada en aquest fitxer.
const cache = new Map();

// El registre de peticions en vol evita el "cache stampede": si deu
// usuaris obren el mateix cim en el mateix segon abans que la primera
// resposta de Google arribi, totes les peticions reaprofiten la mateixa
// promesa en lloc de disparar deu crides idèntiques i quemar quota
// inútilment.
const inFlight = new Map();

// Aquest mètode és el cor del cache: consulta el valor associat a una
// clau, retorna el valor cachejat si encara és vàlid, comparteix la
// petició en vol si n'hi ha una de pendent o, en últim cas, executa el
// loader i emmagatzema el resultat. La clau in-flight s'allibera sempre
// (finally) perquè un loader fallit no deixi peticions atrapades.
async function getOrFetch(key, loader) {
  const cached = cache.get(key);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.value;
  }

  const ongoing = inFlight.get(key);
  if (ongoing) {
    return ongoing;
  }

  const promise = (async () => {
    const value = await loader();
    cache.set(key, {
      value,
      expiresAt: Date.now() + getCacheTtlMs(),
    });
    return value;
  })();

  inFlight.set(key, promise);
  try {
    return await promise;
  } finally {
    inFlight.delete(key);
  }
}

// Aquest servei exposa els punts d'entrada que utilitzen el controller
// per resoldre la previsió per a un cim concret. Tots els mètodes
// validen el seu input i deleguen la xarxa al provider per mantenir la
// responsabilitat separada.
const WeatherService = {

  // Aquest mètode retorna la previsió diària d'un cim concret. El cim
  // s'ha de buscar a la BD per llegir-ne les coordenades exactes; si no
  // existeix es retorna 404 perquè el client distingeixi un peakId
  // invàlid d'una fallada de proveïdor. Internament es demanen sempre
  // els 10 dies màxims i es retalla la llista a la mida sol·licitada:
  // així una crida amb days=3 i una posterior amb days=7 comparteixen
  // la mateixa entrada de cache i evitem una segona petició a Google.
  async getDailyForecastForPeak(peakId, { days = 7 } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const parsedDays = Math.min(Math.max(Number(days) || 7, 1), 10);

    const peak = await PeakModel.findById(parsedPeakId);
    if (!peak) {
      const error = new Error('Peak not found');
      error.statusCode = 404;
      throw error;
    }

    const key = `peak:${parsedPeakId}:daily`;
    const payload = await getOrFetch(key, () =>
      weatherProvider.fetchDailyForecast({
        latitude: Number(peak.latitude),
        longitude: Number(peak.longitude),
        days: 10,
      })
    );

    return {
      peakId: parsedPeakId,
      timeZone: payload.timeZone,
      days: payload.days.slice(0, parsedDays),
    };
  },

  // Aquest mètode retorna la previsió horària d'un cim per a una data
  // concreta dins de l'horitzó disponible. Internament demanem sempre les
  // 240h màximes a Google i filtrem per la data sol·licitada, perquè
  // Google no accepta un startTime arbitrari i el cost d'una crida (240h)
  // és gairebé el mateix que el d'una de 24h. Així la cache reaprofita el
  // mateix payload per a totes les hores del cim, independentment del dia
  // que demani l'usuari.
  async getHourlyForecastForPeak(peakId, isoDate) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const date = requireIsoDate(isoDate, 'date', { allowFuture: true });

    const peak = await PeakModel.findById(parsedPeakId);
    if (!peak) {
      const error = new Error('Peak not found');
      error.statusCode = 404;
      throw error;
    }

    const fullKey = `peak:${parsedPeakId}:hourly`;
    const full = await getOrFetch(fullKey, () =>
      weatherProvider.fetchHourlyForecast({
        latitude: Number(peak.latitude),
        longitude: Number(peak.longitude),
      })
    );

    const hours = full.hours.filter(
      (entry) => entry.localDateTime && entry.localDateTime.startsWith(date)
    );

    if (hours.length === 0) {
      const error = new Error('No hourly forecast available for that date');
      error.statusCode = 404;
      throw error;
    }

    return {
      peakId: parsedPeakId,
      date,
      timeZone: full.timeZone,
      hours,
    };
  },
};

module.exports = WeatherService;

// Exposem una utilitat per netejar la cache des dels tests sense
// haver de reiniciar el procés. No forma part del contracte públic.
module.exports._resetCacheForTests = () => {
  cache.clear();
  inFlight.clear();
};
