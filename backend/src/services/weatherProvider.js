const axios = require('axios');

// Aquest fitxer centralitza la comunicació amb la Google Weather API.
// Permet obtenir la previsió meteorològica i adaptar-la al format que utilitza CiMS.
const GOOGLE_WEATHER_BASE_URL = 'https://weather.googleapis.com/v1';

// Defineix el temps màxim d’espera per a cada petició meteorològica.
// Evita que la pantalla quedi bloquejada si el proveïdor extern triga massa a respondre.
const REQUEST_TIMEOUT_MS = 8000;

// Aquest mapa agrupa les condicions meteorològiques de Google en categories pròpies de CiMS.
// Això permet mostrar icones i textos coherents encara que el proveïdor retorni molts valors diferents.
const CONDITION_MAP = {
  CLEAR: 'SUNNY',
  MOSTLY_CLEAR: 'SUNNY',
  PARTLY_CLOUDY: 'PARTLY_CLOUDY',
  MOSTLY_CLOUDY: 'CLOUDY',
  CLOUDY: 'CLOUDY',
  LIGHT_RAIN_SHOWERS: 'RAINY',
  CHANCE_OF_SHOWERS: 'RAINY',
  SCATTERED_SHOWERS: 'RAINY',
  RAIN_SHOWERS: 'RAINY',
  HEAVY_RAIN_SHOWERS: 'RAINY',
  LIGHT_TO_MODERATE_RAIN: 'RAINY',
  MODERATE_TO_HEAVY_RAIN: 'RAINY',
  RAIN: 'RAINY',
  LIGHT_RAIN: 'RAINY',
  HEAVY_RAIN: 'RAINY',
  RAIN_PERIODICALLY_HEAVY: 'RAINY',
  DRIZZLE: 'RAINY',
  WIND_AND_RAIN: 'RAINY',
  THUNDERSTORM: 'RAINY',
  THUNDERSHOWER: 'RAINY',
  LIGHT_THUNDERSTORM_RAIN: 'RAINY',
  SCATTERED_THUNDERSTORMS: 'RAINY',
  HEAVY_THUNDERSTORM: 'RAINY',
  LIGHT_SNOW_SHOWERS: 'SNOWY',
  CHANCE_OF_SNOW_SHOWERS: 'SNOWY',
  SCATTERED_SNOW_SHOWERS: 'SNOWY',
  SNOW_SHOWERS: 'SNOWY',
  HEAVY_SNOW_SHOWERS: 'SNOWY',
  LIGHT_TO_MODERATE_SNOW: 'SNOWY',
  MODERATE_TO_HEAVY_SNOW: 'SNOWY',
  SNOW: 'SNOWY',
  LIGHT_SNOW: 'SNOWY',
  HEAVY_SNOW: 'SNOWY',
  SNOWSTORM: 'SNOWY',
  SNOW_PERIODICALLY_HEAVY: 'SNOWY',
  HEAVY_SNOW_STORM: 'SNOWY',
  BLOWING_SNOW: 'SNOWY',
  RAIN_AND_SNOW: 'SNOWY',
  HAIL: 'SNOWY',
  HAIL_SHOWERS: 'SNOWY',
  FOG: 'FOGGY',
  LIGHT_FOG: 'FOGGY',
  HAZE: 'FOGGY',
  ICE_FOG: 'FOGGY',
  MIST: 'FOGGY',
  DUST: 'FOGGY',
  SMOKE: 'FOGGY',
  SAND: 'FOGGY',
  SANDSTORM: 'FOGGY',
  DUSTSTORM: 'FOGGY',
};

// Aquest mètode normalitza una condició meteorològica rebuda de Google.
// En casos de vent, utilitza la nuvolositat per aproximar millor l’estat del cel.
function normalizeCondition(googleType, cloudCoverPct) {
  if (!googleType) {
    return 'UNKNOWN';
  }
  if (googleType === 'WINDY' || googleType === 'SQUALL') {
    if (typeof cloudCoverPct !== 'number') {
      return 'PARTLY_CLOUDY';
    }
    if (cloudCoverPct < 25) {
      return 'SUNNY';
    }
    if (cloudCoverPct < 60) {
      return 'PARTLY_CLOUDY';
    }
    return 'CLOUDY';
  }
  return CONDITION_MAP[googleType] || 'UNKNOWN';
}

// Aquest error representa una incidència amb el proveïdor meteorològic.
// Dona al frontend un codi controlat sense exposar detalls interns de Google.
class WeatherProviderError extends Error {
  constructor({ statusCode = 503, internalDetail } = {}) {
    super('La previsió meteorològica no està disponible ara mateix');
    this.name = 'WeatherProviderError';
    this.statusCode = statusCode;
    this.code = 'WEATHER_PROVIDER_UNAVAILABLE';
    this.internalDetail = internalDetail;
  }
}

// Aquest mètode comprova que la clau de Google Weather estigui configurada.
// Sense aquesta clau no es poden fer peticions al proveïdor extern.
function ensureApiKey() {
  const apiKey = process.env.GOOGLE_WEATHER_API_KEY;
  if (!apiKey) {
    throw new WeatherProviderError({
      statusCode: 500,
      internalDetail: 'GOOGLE_WEATHER_API_KEY is not defined',
    });
  }
  return apiKey;
}

// Aquest mètode executa una petició GET a Google Weather.
// També converteix qualsevol error del proveïdor en una resposta controlada per l’aplicació.
async function googleGet(path, params) {
  const apiKey = ensureApiKey();
  try {
    const response = await axios.get(`${GOOGLE_WEATHER_BASE_URL}${path}`, {
      params: { key: apiKey, ...params },
      timeout: REQUEST_TIMEOUT_MS,
    });
    return response.data;
  } catch (error) {
    if (error.response) {
      const status = error.response.status;
      const message = error.response.data?.error?.message || error.message;
      throw new WeatherProviderError({
        internalDetail: `Google Weather API ${status}: ${message}`,
      });
    }
    throw new WeatherProviderError({
      internalDetail: `Google Weather API request failed: ${error.message}`,
    });
  }
}

// Aquest mètode adapta una condició meteorològica al format intern de CiMS.
// Conserva el valor original i afegeix una categoria normalitzada per a la interfície.
function mapCondition(condition, { cloudCoverPct } = {}) {
  if (!condition) {
    return null;
  }
  return {
    type: condition.type ?? null,
    normalized: normalizeCondition(condition.type, cloudCoverPct),
    description: condition.description?.text ?? null,
    iconBaseUri: condition.iconBaseUri ?? null,
  };
}

// Aquest mètode adapta una previsió de mig dia al format intern.
// Recull les dades que el frontend necessita per mostrar pluja, vent, núvols i radiació.
function mapHalfDay(half) {
  if (!half) {
    return null;
  }
  return {
    condition: mapCondition(half.weatherCondition, {
      cloudCoverPct: half.cloudCover ?? undefined,
    }),
    precipProbabilityPct: half.precipitation?.probability?.percent ?? 0,
    precipQuantityMm: half.precipitation?.qpf?.quantity ?? 0,
    thunderstormProbabilityPct: half.thunderstormProbability ?? 0,
    windSpeedKmh: half.wind?.speed?.value ?? null,
    windGustKmh: half.wind?.gust?.value ?? null,
    windDirectionDegrees: half.wind?.direction?.degrees ?? null,
    cloudCoverPct: half.cloudCover ?? null,
    uvIndex: half.uvIndex ?? null,
  };
}

// Aquest mètode adapta la previsió d’un dia complet.
// Prepara temperatures, hores de sol i previsió de dia i nit per al frontend.
function mapDay(raw) {
  const date = formatDisplayDate(raw.displayDate);
  return {
    date,
    minTempC: raw.minTemperature?.degrees ?? null,
    maxTempC: raw.maxTemperature?.degrees ?? null,
    feelsLikeMinC: raw.feelsLikeMinTemperature?.degrees ?? null,
    feelsLikeMaxC: raw.feelsLikeMaxTemperature?.degrees ?? null,
    daytime: mapHalfDay(raw.daytimeForecast),
    nighttime: mapHalfDay(raw.nighttimeForecast),
    sunriseTime: raw.sunEvents?.sunriseTime ?? null,
    sunsetTime: raw.sunEvents?.sunsetTime ?? null,
  };
}

// Aquest mètode adapta la previsió d’una hora concreta.
// Permet mostrar una previsió detallada per franges horàries dins del cim seleccionat.
function mapHour(raw) {
  return {
    startTime: raw.interval?.startTime ?? null,
    localDateTime: formatDisplayDateTime(raw.displayDateTime),
    isDaytime: raw.isDaytime ?? null,
    temperatureC: raw.temperature?.degrees ?? null,
    feelsLikeC: raw.feelsLikeTemperature?.degrees ?? null,
    condition: mapCondition(raw.weatherCondition, {
      cloudCoverPct: raw.cloudCover ?? undefined,
    }),
    precipProbabilityPct: raw.precipitation?.probability?.percent ?? 0,
    precipQuantityMm: raw.precipitation?.qpf?.quantity ?? 0,
    thunderstormProbabilityPct: raw.thunderstormProbability ?? 0,
    windSpeedKmh: raw.wind?.speed?.value ?? null,
    windGustKmh: raw.wind?.gust?.value ?? null,
    windDirectionDegrees: raw.wind?.direction?.degrees ?? null,
    cloudCoverPct: raw.cloudCover ?? null,
    uvIndex: raw.uvIndex ?? null,
    visibilityKm: raw.visibility?.distance ?? null,
    pressureMbar: raw.airPressure?.meanSeaLevelMillibars ?? null,
  };
}

// Aquest mètode transforma la data de Google en format YYYY-MM-DD.
// Facilita comparar i agrupar previsions per dia dins del frontend.
function formatDisplayDate(displayDate) {
  if (!displayDate) {
    return null;
  }
  const year = displayDate.year;
  const month = String(displayDate.month).padStart(2, '0');
  const day = String(displayDate.day).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Aquest mètode transforma una data i hora local de Google en una cadena estable.
// Serveix perquè el frontend pugui mostrar i agrupar les hores sense calcular zones horàries.
function formatDisplayDateTime(displayDateTime) {
  if (!displayDateTime) {
    return null;
  }
  const year = displayDateTime.year;
  const month = String(displayDateTime.month).padStart(2, '0');
  const day = String(displayDateTime.day).padStart(2, '0');
  const hours = String(displayDateTime.hours ?? 0).padStart(2, '0');
  return `${year}-${month}-${day}T${hours}:00:00`;
}

// Aquest mètode recupera la previsió diària d’una coordenada.
// Limita els dies disponibles i retorna una llista preparada per al servei de CiMS.
async function fetchDailyForecast({ latitude, longitude, days = 7 }) {
  const requestedDays = Math.min(Math.max(days, 1), 10);
  const collected = [];
  let timeZoneId = null;
  let pageToken;

  do {
    const data = await googleGet('/forecast/days:lookup', {
      'location.latitude': latitude,
      'location.longitude': longitude,
      days: requestedDays,
      pageSize: requestedDays,
      ...(pageToken ? { pageToken } : {}),
    });

    timeZoneId = data.timeZone?.id ?? timeZoneId;
    for (const day of data.forecastDays || []) {
      collected.push(mapDay(day));
      if (collected.length >= requestedDays) {
        break;
      }
    }
    pageToken = data.nextPageToken;
  } while (pageToken && collected.length < requestedDays);

  return {
    timeZone: timeZoneId,
    days: collected.slice(0, requestedDays),
  };
}

// Aquest mètode recupera la previsió horària d’una coordenada.
// Retorna l’horitzó disponible perquè el servei pugui filtrar després pel dia sol·licitat.
async function fetchHourlyForecast({ latitude, longitude }) {
  const collected = [];
  let timeZoneId = null;
  let pageToken;

  do {
    const data = await googleGet('/forecast/hours:lookup', {
      'location.latitude': latitude,
      'location.longitude': longitude,
      hours: 240,
      pageSize: 240,
      ...(pageToken ? { pageToken } : {}),
    });

    timeZoneId = data.timeZone?.id ?? timeZoneId;
    for (const hour of data.forecastHours || []) {
      collected.push(mapHour(hour));
    }
    pageToken = data.nextPageToken;
  } while (pageToken);

  return {
    timeZone: timeZoneId,
    hours: collected,
  };
}

module.exports = {
  fetchDailyForecast,
  fetchHourlyForecast,
  normalizeCondition,
  WeatherProviderError,
};