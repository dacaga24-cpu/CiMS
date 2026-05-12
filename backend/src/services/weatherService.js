const pool = require('../config/db');
const PeakModel = require('../models/peakModel');
const weatherProvider = require('./weatherProvider');
const {
  badRequest,
  requireInteger,
  requireIsoDate,
} = require('../utils/validation');

// Aquest fitxer concentra la lògica meteorològica de CiMS. La seva funció
// és orquestrar tres rols complementaris: parlar amb el proveïdor (a
// través de weatherProvider), mantenir una capa de cache que protegeixi
// la quota de Google i resoldre el filtre per comarca que utilitzen el
// mapa i el catàleg. Els controllers consumeixen aquest mòdul sense
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

// Aquest bloc manté el càlcul dels centroides de cada comarca, que són la
// coordenada representativa que enviem a Google quan resolem el filtre
// regional. Es calculen "lazy" en el primer ús perquè un càlcul eager a
// l'arrencada faria que un problema temporal de connexió a la BD tombés
// el servei sencer (avui que el clima és secundari). La promesa es
// memoritza per garantir que el càlcul només es fa un cop per procés;
// si falla, es descarta perquè la crida següent pugui tornar a provar-ho
// en lloc d'arrossegar l'error.
//
// Limitació coneguda: si s'afegeixen cims o comarques en calent, el
// centroide no s'actualitza fins al següent reinici. Per a MVP és
// acceptable; quan calgui refresc dinàmic, exposar una funció pública
// d'invalidació.
let regionCentroidsPromise = null;

async function getRegionCentroids() {
  if (regionCentroidsPromise) {
    return regionCentroidsPromise;
  }

  regionCentroidsPromise = (async () => {
    // El HAVING blinda davant cims amb latitud o longitud nul·les: sense
    // aquesta defensa, AVG retornaria null per a la comarca afectada i
    // Number(null) seria 0, fent que enviéssim coordenades (0,0) — al
    // mig de l'Atlàntic — a Google.
    const sql = `
      SELECT pr.region_id AS id,
             r.name       AS name,
             AVG(p.latitude)  AS lat,
             AVG(p.longitude) AS lng
      FROM peak_regions pr
      INNER JOIN peaks   p ON p.id = pr.peak_id
      INNER JOIN regions r ON r.id = pr.region_id
      WHERE p.latitude IS NOT NULL
        AND p.longitude IS NOT NULL
      GROUP BY pr.region_id, r.name
      HAVING lat IS NOT NULL AND lng IS NOT NULL
    `;
    const [rows] = await pool.execute(sql);

    const map = new Map();
    for (const row of rows) {
      map.set(Number(row.id), {
        id: Number(row.id),
        name: row.name,
        latitude: Number(row.lat),
        longitude: Number(row.lng),
      });
    }
    return map;
  })().catch((error) => {
    // Es reseteja la promesa per no quedar atrapats en un estat fallit
    // permanent: la crida següent farà un nou intent contra la BD.
    regionCentroidsPromise = null;
    throw error;
  });

  return regionCentroidsPromise;
}

// Aquest mètode interpreta el paràmetre conditions del filtre i el
// converteix en un Set d'etiquetes normalitzades validades. Accepta
// tant un array (cas en què el client passa diverses entrades amb el
// mateix nom) com una cadena separada per comes (cas habitual quan el
// frontend serialitza filtres a la query string). Qualsevol valor fora
// de les cinc categories conegudes és un 400 explícit perquè el
// frontend pugui corregir el contracte abans que arribi una petició
// silenciosament buida.
function parseConditionsParam(conditions, fieldName = 'weatherConditions') {
  if (conditions === undefined || conditions === null || conditions === '') {
    return new Set();
  }

  let parts;
  if (Array.isArray(conditions)) {
    parts = conditions;
  } else if (typeof conditions === 'string') {
    parts = conditions.split(',');
  } else {
    throw badRequest(
      `Invalid ${fieldName}: must be a comma-separated list of weather condition codes`
    );
  }

  const allowed = new Set(weatherProvider.NORMALIZED_CONDITIONS);
  const result = new Set();
  for (const raw of parts) {
    const value = String(raw).trim().toUpperCase();
    if (!value) continue;
    if (!allowed.has(value)) {
      throw badRequest(
        `Invalid ${fieldName}: "${raw}". Allowed values: ${weatherProvider.NORMALIZED_CONDITIONS.join(', ')}`
      );
    }
    result.add(value);
  }
  return result;
}

// Aquest servei exposa els punts d'entrada que utilitzen el controller i
// el filtre del catàleg. Tots els mètodes valid del seu input i deleguen
// la xarxa al provider per mantenir la responsabilitat separada.
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

  // Aquest mètode retorna la previsió diària agregada per a una comarca
  // a partir del seu centroide. Serveix tant per al filtre com per
  // exposar el contracte de regió a través d'un endpoint públic, perquè
  // un client (per exemple, una versió futura amb vista comarcal) pugui
  // demanar la previsió d'una sola comarca sense haver de carregar tots
  // els cims que conté. Es demana sempre l'horitzó màxim (10 dies)
  // perquè el filtre pugui reutilitzar la mateixa entrada per a
  // qualsevol data dins el rang.
  async getRegionalSummary(regionId, isoDate) {
    const parsedRegionId = requireInteger(regionId, 'regionId');
    const date = requireIsoDate(isoDate, 'date', { allowFuture: true });

    const centroids = await getRegionCentroids();
    const region = centroids.get(parsedRegionId);
    if (!region) {
      const error = new Error('Region not found');
      error.statusCode = 404;
      throw error;
    }

    const key = `region:${parsedRegionId}:daily`;
    const payload = await getOrFetch(key, () =>
      weatherProvider.fetchDailyForecast({
        latitude: region.latitude,
        longitude: region.longitude,
        days: 10,
      })
    );

    const day = payload.days.find((entry) => entry.date === date);
    if (!day) {
      const error = new Error('No forecast available for that date in this region');
      error.statusCode = 404;
      throw error;
    }

    return {
      regionId: parsedRegionId,
      regionName: region.name,
      date,
      timeZone: payload.timeZone,
      forecast: day,
    };
  },

  // Aquest mètode és el motor del filtre per clima del mapa i del
  // catàleg. Donada una data i un conjunt de condicions normalitzades,
  // retorna els identificadors de les comarques on la previsió diurna
  // coincideix amb alguna de les condicions sol·licitades. El consumidor
  // (peakService) traduirà aquesta llista en un AND amb la resta de
  // filtres i farà el SQL final sobre la taula peak_regions.
  //
  // Decisió de Phase 4: el filtre només avalua la previsió diürna
  // (daytime). Una excursió de muntanya es planifica per al dia, i un
  // canvi de condició nocturna no canviaria el comportament esperat
  // ("vull anar a un cim demà amb sol" no es veu afectat per la pluja
  // de la nit). Si en algun moment cal cobrir el cas "vull veure
  // l'aurora amb cel net", caldria afegir una variant que llegeixi
  // nighttime.condition o exposar dos filtres independents.
  //
  // Es treballa contra els centroides perquè el cost de demanar la
  // previsió per a tots ~999 cims hauria estat inviable: amb regions
  // (~13) cada filtre fred costa una desena de crides a Google, totes
  // en paral·lel, i s'amorteixen contra la cache durant l'hora següent.
  //
  // Una regió que falli (Google retorna error) s'ignora silenciosament
  // en aquest filtre: és preferible mostrar a l'usuari els resultats
  // parcials de la resta de comarques que retornar una llista buida que
  // sembli "no hi ha cims per a aquest filtre". L'incident queda als
  // logs perquè es pugui investigar si és sistemàtic.
  async peaksByWeather({ date, conditions }) {
    const isoDate = requireIsoDate(date, 'weatherDate', { allowFuture: true });
    const wanted = parseConditionsParam(conditions, 'weatherConditions');

    if (wanted.size === 0) {
      throw badRequest('At least one weatherCondition is required');
    }

    const centroids = await getRegionCentroids();
    const regions = Array.from(centroids.values());

    let failureCount = 0;
    const results = await Promise.all(
      regions.map(async (region) => {
        const key = `region:${region.id}:daily`;
        try {
          const payload = await getOrFetch(key, () =>
            weatherProvider.fetchDailyForecast({
              latitude: region.latitude,
              longitude: region.longitude,
              days: 10,
            })
          );
          const day = payload.days.find((entry) => entry.date === isoDate);
          if (!day || !day.daytime || !day.daytime.condition) {
            return null;
          }
          return wanted.has(day.daytime.condition.normalized)
            ? region.id
            : null;
        } catch (error) {
          // S'inclou el codi i el nom de l'error per distingir clarament
          // un fallo de proveïdor (WeatherProviderError, 503) d'un bug
          // intern de mapping (TypeError, RangeError...) que mai s'hauria
          // d'estar tragant aquí. El stack es loguega també perquè els
          // errors no-proveïdor són sempre incidències a investigar.
          failureCount += 1;
          console.warn(
            `[weather] regional forecast failed for region ${region.id}: ` +
              `code=${error.code || 'n/a'} name=${error.name || 'n/a'} ` +
              `message=${error.message}`
          );
          if (!error.code) {
            console.warn(error.stack);
          }
          return null;
        }
      })
    );

    // Si totes les comarques han fallat, no es pot oferir cap resposta
    // útil. En aquest cas es propaga un WeatherProviderError perquè el
    // client mostri un missatge específic ("filtre meteorològic no
    // disponible") en comptes d'una llista buida que sembli no tenir
    // cap cim que casi. Si almenys una comarca ha respost, es manté el
    // comportament tolerant: es retornen els ids dels que han matchejat
    // i la resta s'ignora silenciosament als logs.
    if (regions.length > 0 && failureCount === regions.length) {
      throw new weatherProvider.WeatherProviderError({
        internalDetail:
          `All ${regions.length} regions failed to resolve against the weather provider`,
      });
    }

    return results.filter((id) => id !== null);
  },

  // Aquest mètode normalitza un valor de query string en un array
  // d'identificadors de regió per al filtre del catàleg. Es manté com a
  // helper exposat perquè peakService no hagi de duplicar la validació
  // de data ni la traducció de condicions; rep els paràmetres crus del
  // request i decideix si activa el filtre regional o no.
  //
  // El filtre meteorològic només té sentit quan arriben tots dos
  // paràmetres. Si en falta un (per exemple, un client HTTP que envia
  // només weatherDate o només weatherConditions), no hi ha prou
  // informació per resoldre la intersecció: en aquest cas, en lloc de
  // propagar un 400 que probablement confondria el client, es tracta
  // com a "sense filtre meteorològic" i el catàleg torna la llista
  // sencera. El bottom-sheet del frontend ja garanteix que les dues
  // parts viatgen juntes, així que aquest camí només s'activa per a
  // clients externs.
  async resolveRegionIdsByWeather({ weatherDate, weatherConditions }) {
    if (!weatherDate || !weatherConditions) {
      return null;
    }
    return WeatherService.peaksByWeather({
      date: weatherDate,
      conditions: weatherConditions,
    });
  },
};

module.exports = WeatherService;

// Exposem una utilitat per netejar la cache des dels tests sense
// haver de reiniciar el procés. No forma part del contracte públic.
module.exports._resetCacheForTests = () => {
  cache.clear();
  inFlight.clear();
  regionCentroidsPromise = null;
};
