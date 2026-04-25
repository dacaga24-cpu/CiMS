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

module.exports = {
  badRequest,
  parseOptionalInteger,
  requireInteger,
};
