const axios = require('axios');

// Aquest fitxer encapsula la comunicació amb la Google Weather API.
// La seva funció és fer les peticions HTTP, normalitzar la resposta al
// format intern de CiMS i centralitzar la gestió d'errors del proveïdor.
// La resta del backend mai parla directament amb Google: així, si en el
// futur es canvia de proveïdor o s'afegeix una segona font, només cal
// modificar aquest mòdul.

const GOOGLE_WEATHER_BASE_URL = 'https://weather.googleapis.com/v1';

// Es defineix un timeout curt perquè un cim sense previsió disponible no
// bloquegi la càrrega del detall ni del filtre. Si Google triga més de 8
// segons, és preferible retornar 503 i deixar que el frontend mostri un
// missatge clar abans que mantenir l'usuari esperant.
const REQUEST_TIMEOUT_MS = 8000;

// Aquest mapa tradueix els tipus de condició crus de Google a les sis
// categories normalitzades de CiMS (SUNNY, PARTLY_CLOUDY, CLOUDY, RAINY,
// SNOWY, FOGGY). Es manté explícit (no es deriva del nom) perquè Google
// té molts valors propers — "LIGHT_RAIN_SHOWERS", "CHANCE_OF_SHOWERS",
// "RAIN_PERIODICALLY_HEAVY" — i la traducció requereix decisió humana
// sobre on encaixa cadascun. Si arriba un tipus no llistat, es marca
// com a UNKNOWN.
//
// WINDY i SQUALL no apareixen aquí intencionadament: són casos especials
// on Google diu "el viento es el aspecto més notable" però no et diu
// l'estat real del cel. Es resolen a normalizeCondition() llegint
// cloudCover, que Google envia com a camp independent.
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

// Aquest mètode tradueix un tipus de condició cru de Google al grup
// normalitzat. Per a la majoria de tipus n'hi ha prou amb una consulta
// directa a CONDITION_MAP. Els casos especials WINDY i SQUALL no
// transmeten l'estat real del cel per ells mateixos (Google els fa
// servir quan el vent és el tret dominant), així que es resolen mirant
// cloudCover, que arriba en un camp independent del payload. Si
// cloudCover no està informat, es retorna PARTLY_CLOUDY com a punt
// mitjà raonable. Per a tipus desconeguts es retorna UNKNOWN: el
// frontend pot mostrar igualment el text descriptiu original sense que
// el pintat es trenqui.
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

// Aquest error indica que el proveïdor extern no ha pogut atendre la
// petició. El missatge públic és sempre genèric perquè cap detall
// operacional de Google (quota esgotada, clau invàlida, project IDs,
// missatges 4xx amb context intern) viatgi al client. Els detalls
// concrets viuen a `internalDetail` i s'escriuen als logs del servidor.
// El frontend distingeix la incidència pel codi simbòlic
// WEATHER_PROVIDER_UNAVAILABLE, no pel text.
class WeatherProviderError extends Error {
  constructor({ statusCode = 503, internalDetail } = {}) {
    super('La previsió meteorològica no està disponible ara mateix');
    this.name = 'WeatherProviderError';
    this.statusCode = statusCode;
    this.code = 'WEATHER_PROVIDER_UNAVAILABLE';
    this.internalDetail = internalDetail;
  }
}

// Aquest mètode comprova que la clau de l'API estigui configurada abans de
// fer cap petició. Es valida en cada crida en lloc d'un cop al carregar el
// mòdul perquè els tests poden injectar la variable d'entorn després
// d'importar el fitxer; carregar-la una sola vegada faria que les proves no
// veiessin canvis posteriors a process.env.
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

// Aquest mètode executa una crida GET a la Google Weather API i normalitza
// qualsevol error en un WeatherProviderError. Els errors de xarxa, els 4xx
// del proveïdor i els timeouts s'unifiquen perquè la capa de servei no
// hagi de distingir entre fallades de transport i fallades d'aplicació.
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

// Aquest mètode tradueix l'objecte weatherCondition cru de Google al
// format intern. Es conserva el camp type original perquè permeti
// diagnosticar quins valors arriben de Google sense haver de mirar logs,
// i s'afegeix la versió normalitzada per a la UI. El cloudCoverPct viatja
// com a opció perquè el cridant (mapHalfDay/mapHour) el conegui i ens
// permeti desambiguar tipus com WINDY o SQUALL. iconBaseUri es passa tal
// qual perquè el frontend pugui construir la URL final de la icona si
// algun cop decideix utilitzar-la.
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

// Aquest mètode tradueix un bloc daytimeForecast o nighttimeForecast al
// format intern. S'omet deliberadament relativeHumidity perquè el producte
// ha decidit no exposar-la. Tampoc s'inclouen camps com iceThickness o
// heatIndex que avui no es mostren a la UI: així el payload és mes lleuger.
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

// Aquest mètode tradueix un dia complet de la resposta de Google al format
// intern. La data es reconstrueix a partir de displayDate per evitar
// dependre del fus horari del servidor: si fessim servir interval.startTime
// i el servidor estigués en UTC, podria assignar al dia anterior previsions
// pensades per a la matinada del dia local.
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

// Aquest mètode tradueix una hora concreta al format intern. Conserva la
// marca temporal en UTC (interval.startTime) i una versió "local" que
// uneix displayDateTime perquè el frontend pugui agrupar les hores per dia
// sense convertir zones horàries manualment.
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

// Aquest mètode normalitza el bloc displayDate de Google a una cadena
// YYYY-MM-DD per facilitar comparacions amb dates rebudes pel frontend.
function formatDisplayDate(displayDate) {
  if (!displayDate) {
    return null;
  }
  const year = displayDate.year;
  const month = String(displayDate.month).padStart(2, '0');
  const day = String(displayDate.day).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Aquest mètode normalitza displayDateTime a una cadena ISO local
// (sense Z, perquè és l'hora del fus del cim). El frontend pot decidir
// si la formata com a "08:00" o si la compara amb el dia seleccionat.
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

// Aquest mètode recupera la previsió diària per a una coordenada. days
// queda limitat a 10 perquè és el màxim que retorna Google; valors superiors
// es retallen silenciosament per protegir el cridant de configuracions
// errònies. La paginació s'oculta: el cridant rep sempre una llista plana
// amb la primera pàgina (pageSize=days) i, si calguessin més pàgines, es
// continuen demanant fins arribar a la mida sol·licitada.
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

// Aquest mètode recupera la previsió horària per a una coordenada. Sempre
// retorna fins a 240 hores (10 dies × 24h) en una única crida transparent
// al cridant; el filtre per data el fa el servei a partir d'aquesta llista
// completa, perquè és més barat cachejar el bloc sencer que demanar només
// les 24h del dia que demana l'usuari (Google no accepta startTime
// arbitrari, només "des d'ara"). Es prova pageSize=240 per estalviar
// round-trips: si Google l'accepta, una sola petició basta; si retalla a
// menys (p. ex. 24), el while continua descarregant pàgines fins a
// completar les 240 hores. Un rebuig amb 400 propagaria com a
// WeatherProviderError i interrompria la càrrega — no degrada
// silenciosament.
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
