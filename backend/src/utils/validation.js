// Utilitats compartides per validar i normalitzar paràmetres rebuts en
// peticions HTTP. Centralitzat per garantir un contracte de retorn coherent
// (null, undefined, número) entre serveis.

// Crea un error de validació amb codi 400. El gestor d'errors centralitzat
// el convertirà en una resposta HTTP coherent.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Interpreta un valor opcional com a enter dins d'un mínim donat. undefined
// quan el valor no s'ha enviat, perquè el caller ho llegeixi com a "sense
// filtre". Llança 400 si arriba però no és un enter vàlid; el missatge
// inclou el nom del camp per facilitar el diagnòstic des del client.
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

// Versió obligatòria: l'absència és error. S'usa per a paràmetres que mai
// poden faltar (per exemple, l'identificador d'un recurs a la URL).
function requireInteger(value, fieldName, { min = 1 } = {}) {
  if (value === undefined || value === null || value === '') {
    throw badRequest(`Missing required field: ${fieldName}`);
  }
  return parseOptionalInteger(value, fieldName, { min });
}

// Interpreta una data ISO YYYY-MM-DD. Es valida tant el format (regex) com
// la coherència del calendari (2026-02-31 no existeix tot i passar el regex)
// reconstruint la cadena des del Date i comparant. Per defecte rebutja dates
// futures: una ascensió només pot ser passada o d'avui.
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
  // Reconstrucció: `new Date('2026-02-31Z')` interpreta com a 2026-03-03
  // enlloc de donar error. Si la cadena reconstruïda no coincideix, falsa.
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

// Versió obligatòria de parseOptionalIsoDate.
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
