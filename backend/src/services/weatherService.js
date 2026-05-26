const PeakModel = require('../models/peakModel');
const weatherProvider = require('./weatherProvider');
const { requireInteger, requireIsoDate } = require('../utils/validation');

// Aquest servei centralitza la lògica meteorològica de CiMS.
// Consulta la previsió externa, valida les dades rebudes i manté una cache per reduir crides a Google.
const DEFAULT_CACHE_TTL_MS = 60 * 60 * 1000;

// Aquesta funció obté la durada configurada de la cache.
// Si no hi ha cap valor vàlid a l’entorn, aplica el temps per defecte.
function getCacheTtlMs() {
  const fromEnv = Number(process.env.WEATHER_CACHE_TTL_MS);
  if (Number.isFinite(fromEnv) && fromEnv > 0) {
    return fromEnv;
  }
  return DEFAULT_CACHE_TTL_MS;
}

// Aquesta cache guarda temporalment les previsions ja consultades.
// Evita repetir peticions externes quan diversos usuaris consulten el mateix cim.
const cache = new Map();

// Aquest registre agrupa peticions iguals que encara estan en curs.
// Això evita fer diverses crides simultànies al proveïdor per obtenir la mateixa previsió.
const inFlight = new Map();

// Aquest mètode retorna una resposta cachejada o executa la càrrega si cal.
// També reutilitza peticions en curs per reduir consum de quota i temps d’espera.
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

const WeatherService = {

  // Retorna la previsió diària d’un cim concret.
  // Busca les coordenades del cim, consulta la previsió i limita els dies retornats segons la petició.
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

  // Retorna la previsió horària d’un cim per a una data concreta.
  // Filtra l’horitzó disponible per mostrar només les hores del dia sol·licitat.
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

// Aquesta utilitat neteja la cache durant les proves.
// Permet comprovar el comportament del servei sense reiniciar el procés.
module.exports._resetCacheForTests = () => {
  cache.clear();
  inFlight.clear();
};