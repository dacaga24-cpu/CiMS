// Utilitats per treballar amb dates en hora local de Madrid. La finestra del
// repte mensual s'ha de definir des del primer dia 00:00 fins l'últim 23:59:59
// independentment de la timezone del servidor (Cloud Run corre en UTC). Les
// dates es guarden a la BD com a string 'YYYY-MM-DD HH:MM:SS' per evitar
// conversions implícites del driver mysql2.

const MADRID_TIMEZONE = 'Europe/Madrid';

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

// Extreu les parts d'un Date interpretat en hora Madrid.
//
// El "% 24" sobre l'hora cobreix una particularitat d'algunes implementacions
// d'Intl amb hour12: false que retornen "24" enlloc de "00" a mitjanit; sense
// la normalització una mitjanit es convertiria en una cadena DATETIME invàlida.
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

// Any i mes actuals segons l'hora local de Madrid: el "mes en curs" sempre
// es defineix des del calendari que veu l'usuari final.
function getCurrentMadridYearMonth() {
  const { year, month } = madridParts(new Date());
  return { year, month };
}

// Instant actual en hora Madrid com a 'YYYY-MM-DD HH:MM:SS' apte per a una
// columna DATETIME. S'usa per segellar level_X_completed_at.
function getCurrentMadridDateTimeString() {
  const { year, month, day, hour, minute, second } = madridParts(new Date());
  return formatDateTime(year, month, day, hour, minute, second);
}

// Últim dia d'un mes donat. `new Date(year, month, 0)` retorna l'últim dia
// del mes anterior al "month" (1-indexed pel constructor), de manera que
// passant el mes en base 1 obtenim directament el nombre de dies desitjat.
function lastDayOfMonth(year, month) {
  return new Date(year, month, 0).getDate();
}

// Fronteres d'un mes natural en hora Madrid llestes per a una columna DATETIME:
// del dia 1 a 00:00:00 fins l'últim dia a 23:59:59 (inclusiu).
function getMonthBoundaryStrings(year, month) {
  const lastDay = lastDayOfMonth(year, month);
  return {
    startsAt: formatDateTime(year, month, 1, 0, 0, 0),
    endsAt: formatDateTime(year, month, lastDay, 23, 59, 59),
  };
}

// Fronteres com a 'YYYY-MM-DD' sense hora, per filtrar la columna ascent_date
// (de tipus DATE). Helper separat de getMonthBoundaryStrings per deixar
// explícit que cada format respon a un tipus de columna diferent.
function getMonthDateBoundaryStrings(year, month) {
  const lastDay = lastDayOfMonth(year, month);
  return {
    startDate: `${pad4(year)}-${pad2(month)}-01`,
    endDate: `${pad4(year)}-${pad2(month)}-${pad2(lastDay)}`,
  };
}

// Mes anterior al donat. S'usa per evitar repetir el tipus de repte dos
// mesos seguits quan hi ha més d'un tipus disponible.
function getPreviousYearMonth(year, month) {
  if (month === 1) {
    return { year: year - 1, month: 12 };
  }
  return { year, month: month - 1 };
}

// 'YYYY-MM-DD HH:MM:SS' amb camps zero-padded. Únic format que enviem a
// MySQL per a DATETIME des d'aquest mòdul.
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
