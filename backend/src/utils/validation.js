// Aquest fitxer agrupa utilitats compartides per validar paràmetres de peticions HTTP.
// Centralitza criteris comuns perquè els serveis tractin les dades rebudes de manera coherent.

// Aquest mètode crea un error de validació amb codi 400.
// El gestor d’errors el convertirà en una resposta HTTP clara per al client.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest mètode interpreta un valor opcional com un enter.
// Si el valor no s’ha enviat, retorna undefined perquè es pugui tractar com a filtre absent.
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

// Aquest mètode interpreta un valor obligatori com un enter.
// S’utilitza per validar identificadors o camps que no poden faltar.
function requireInteger(value, fieldName, { min = 1 } = {}) {
  if (value === undefined || value === null || value === '') {
    throw badRequest(`Missing required field: ${fieldName}`);
  }
  return parseOptionalInteger(value, fieldName, { min });
}

// Aquest mètode valida una data opcional en format YYYY-MM-DD.
// Retorna la data normalitzada o undefined si el camp no s’ha enviat.
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
  // Aquesta comprovació evita acceptar dates inexistents del calendari.
  // La data reconstruïda ha de coincidir exactament amb el valor rebut.
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

// Aquest mètode valida una data obligatòria en format YYYY-MM-DD.
// Llança un error si el valor no s’ha enviat.
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