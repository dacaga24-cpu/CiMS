// Aquest fitxer agrupa utilitats per treballar amb dates en hora local de Madrid.
// Permet calcular els límits del repte mensual sense dependre de la zona horària del servidor.

const MADRID_TIMEZONE = 'Europe/Madrid';

// Aquest formatador obté les parts d’una data segons l’hora de Madrid.
// Serveix com a base per calcular mesos, dies i hores tal com els veu l’usuari.
const madridFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: MADRID_TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false,
});

// Aquesta funció extreu les parts d’una data en hora Madrid.
// Retorna valors numèrics preparats per construir dates i hores estables.
function madridParts(date) {
  const parts = Object.fromEntries(
    madridFormatter.formatToParts(date).map((part) => [part.type, part.value])
  );
  return {
    year: Number(parts.year),
    month: Number(parts.month),
    day: Number(parts.day),
    hour: Number(parts.hour) % 24,
    minute: Number(parts.minute),
    second: Number(parts.second),
  };
}

// Retorna l’any i el mes actuals segons l’hora local de Madrid.
// Aquesta informació determina quin repte mensual està actiu.
function getCurrentMadridYearMonth() {
  const { year, month } = madridParts(new Date());
  return { year, month };
}

// Retorna l’instant actual en hora Madrid com a cadena DATETIME.
// S’utilitza per registrar quan l’usuari completa nivells del repte mensual.
function getCurrentMadridDateTimeString() {
  const { year, month, day, hour, minute, second } = madridParts(new Date());
  return formatDateTime(year, month, day, hour, minute, second);
}

// Calcula l’últim dia d’un mes concret.
// És necessari per construir correctament els límits mensuals.
function lastDayOfMonth(year, month) {
  return new Date(year, month, 0).getDate();
}

// Retorna l’inici i el final d’un mes natural en format DATETIME.
// Aquestes fronteres defineixen el període complet del repte mensual.
function getMonthBoundaryStrings(year, month) {
  const lastDay = lastDayOfMonth(year, month);
  return {
    startsAt: formatDateTime(year, month, 1, 0, 0, 0),
    endsAt: formatDateTime(year, month, lastDay, 23, 59, 59),
  };
}

// Retorna l’inici i el final d’un mes natural en format DATE.
// S’utilitza per filtrar ascensions, ja que la seva data no inclou hora.
function getMonthDateBoundaryStrings(year, month) {
  const lastDay = lastDayOfMonth(year, month);
  return {
    startDate: `${pad4(year)}-${pad2(month)}-01`,
    endDate: `${pad4(year)}-${pad2(month)}-${pad2(lastDay)}`,
  };
}

// Retorna l’any i el mes anteriors al període indicat.
// Permet comparar el repte actual amb el del mes passat.
function getPreviousYearMonth(year, month) {
  if (month === 1) {
    return { year: year - 1, month: 12 };
  }
  return { year, month: month - 1 };
}

// Composa una cadena DATETIME amb el format esperat per MySQL.
// Centralitza el format per evitar conversions implícites de dates.
function formatDateTime(year, month, day, hour, minute, second) {
  return (
    `${pad4(year)}-${pad2(month)}-${pad2(day)} ` +
    `${pad2(hour)}:${pad2(minute)}:${pad2(second)}`
  );
}

function pad2(value) {
  return String(value).padStart(2, '0');
}

function pad4(value) {
  return String(value).padStart(4, '0');
}

module.exports = {
  MADRID_TIMEZONE,
  getCurrentMadridYearMonth,
  getCurrentMadridDateTimeString,
  getMonthBoundaryStrings,
  getMonthDateBoundaryStrings,
  getPreviousYearMonth,
  lastDayOfMonth,
};