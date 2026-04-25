// Aquest fitxer agrupa utilitats compartides per validar i normalitzar paràmetres
// rebuts en peticions HTTP. Centralitzar aquesta lògica evita que cada servei
// dupliqui el seu propi parser amb petites variacions, cosa que abans feia que
// el contracte de retorn (null, undefined, número) no fos coherent entre fitxers.

// Aquest mètode crea un error de validació amb codi 400.
// El gestor d'errors centralitzat el convertirà en una resposta HTTP coherent.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest mètode interpreta un valor opcional com un enter dins d'un mínim donat.
// Si el valor no s'ha enviat (undefined, null o cadena buida) retorna undefined,
// cosa que els crida poden interpretar com "sense filtre". Si el valor s'ha
// enviat però no es pot interpretar com un enter vàlid, llança un error 400 amb
// un missatge que inclou el nom del camp per facilitar el diagnòstic des del client.
function parseOptionalInteger(value, fieldName, { min = 1 } = {}) {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min) {
    throw badRequest(
      `Invalid ${fieldName}: must be an integer greater than or equal to ${min}`
    );
  }
  return parsed;
}

// Aquest mètode interpreta un valor obligatori com un enter dins d'un mínim donat.
// A diferència de parseOptionalInteger, aquí l'absència del valor també és un error,
// perquè el cridant l'utilitza per a paràmetres que mai poden faltar (per exemple,
// l'identificador d'un recurs a la URL).
function requireInteger(value, fieldName, { min = 1 } = {}) {
  if (value === undefined || value === null || value === '') {
    throw badRequest(`Missing required field: ${fieldName}`);
  }
  return parseOptionalInteger(value, fieldName, { min });
}

// Aquest mètode interpreta una data en format ISO YYYY-MM-DD i la retorna
// normalitzada com a string. Si el valor no s'ha enviat retorna undefined,
// cosa que els crida poden interpretar com "no actualitzar aquest camp".
// Es rebutgen les dates futures perquè una ascensió només pot ser passada o
// d'avui. Es valida tant el format amb regex com la coherència del calendari
// (per exemple, 2026-02-31 no existeix encara que el regex el doni per bo).
function parseOptionalIsoDate(value, fieldName, { allowFuture = false } = {}) {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }
  if (typeof value !== 'string') {
    throw badRequest(`Invalid ${fieldName}: must be a string in YYYY-MM-DD format`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw badRequest(`Invalid ${fieldName}: must be in YYYY-MM-DD format`);
  }
  const parsed = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) {
    throw badRequest(`Invalid ${fieldName}: not a real calendar date`);
  }
  // Es comprova la coherència recompondre la data des dels seus components,
  // ja que `new Date('2026-02-31Z')` interpreta com a 2026-03-03 en lloc de
  // donar error. Si la cadena reconstruïda no coincideix, la data és falsa.
  const reconstructed = parsed.toISOString().slice(0, 10);
  if (reconstructed !== value) {
    throw badRequest(`Invalid ${fieldName}: not a real calendar date`);
  }
  if (!allowFuture) {
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    if (parsed.getTime() > today.getTime()) {
      throw badRequest(`Invalid ${fieldName}: cannot be in the future`);
    }
  }
  return value;
}

// Versió obligatòria de parseOptionalIsoDate. Llança si el valor no s'ha
// enviat, perquè el cridant l'utilitza per a camps que mai poden faltar
// (per exemple, la data d'una ascensió en una creació nova).
function requireIsoDate(value, fieldName, options = {}) {
  if (value === undefined || value === null || value === '') {
    throw badRequest(`Missing required field: ${fieldName}`);
  }
  return parseOptionalIsoDate(value, fieldName, options);
}

module.exports = {
  badRequest,
  parseOptionalInteger,
  requireInteger,
  parseOptionalIsoDate,
  requireIsoDate,
};
