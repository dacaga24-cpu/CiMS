// Aquest fitxer agrupa utilitats per treballar amb dates en hora local de
// Madrid. La timezone es fixa explícitament perquè la finestra del repte
// mensual s'ha de definir des del primer dia del mes a les 00:00 fins
// l'últim a les 23:59:59 amb independència de la timezone del servidor
// (Cloud Run corre en UTC). Tot el que s'escriu a la base de dades es
// guarda com a string 'YYYY-MM-DD HH:MM:SS' en hora Madrid, així evitem
// qualsevol conversió implícita del driver mysql2.

const MADRID_TIMEZONE = 'Europe/Madrid';

// Aquest formatador retorna les parts d'una data ja en hora Madrid. S'usa
// com a base per saber quin any/mes/dia i hora estem segons el calendari
// que veu l'usuari final, no el del servidor.
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

// Aquesta funció extreu les parts d'un Date interpretat en hora Madrid.
// El resultat sempre conté any, mes, dia, hora, minut i segon com a
// nombres, llestos per compondre un string per a la base de dades.
//
// El "% 24" sobre l'hora cobreix una particularitat històrica d'algunes
// implementacions d'Intl amb hour12: false que retornen "24" en comptes
// de "00" per a la mitjanit. Sense aquesta normalització una mitjanit
// es convertiria en una cadena DATETIME invàlida.
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

// Retorna l'any i el mes actuals segons l'hora local de Madrid. És el
// punt d'entrada principal per saber a quin repte estem associats ara
// mateix, ja que el "mes en curs" sempre es defineix des del calendari
// que veu l'usuari final.
function getCurrentMadridYearMonth() {
  const { year, month } = madridParts(new Date());
  return { year, month };
}

// Retorna l'instant actual en hora Madrid com a string 'YYYY-MM-DD HH:MM:SS'
// apte per a una columna DATETIME de MySQL. S'utilitza per segellar els
// camps level_X_completed_at en el moment exacte en què l'usuari supera
// un nivell del repte.
function getCurrentMadridDateTimeString() {
  const { year, month, day, hour, minute, second } = madridParts(new Date());
  return formatDateTime(year, month, day, hour, minute, second);
}

// Calcula l'últim dia d'un mes donat. La construcció `new Date(year, month, 0)`
// retorna l'últim dia del mes anterior al "month" indicat (1-indexed pel
// segon paràmetre del constructor), de manera que passant el mes en base 1
// obtenim directament el nombre de dies del mes desitjat.
function lastDayOfMonth(year, month) {
  return new Date(year, month, 0).getDate();
}

// Retorna les fronteres d'un mes natural en hora Madrid com a strings
// llestos per ser desats a una columna DATETIME. El primer instant és
// el dia 1 a les 00:00:00 i l'últim és el dia final a les 23:59:59,
// inclusiu. Aquest format coincideix exactament amb el que el frontend
// rebrà a la resposta, sense haver de fer cap conversió addicional.
function getMonthBoundaryStrings(year, month) {
  const lastDay = lastDayOfMonth(year, month);
  return {
    startsAt: formatDateTime(year, month, 1, 0, 0, 0),
    endsAt: formatDateTime(year, month, lastDay, 23, 59, 59),
  };
}

// Retorna les fronteres d'un mes natural com a strings 'YYYY-MM-DD' sense
// hora. S'utilitza per filtrar la columna ascent_date (de tipus DATE), que
// no porta hora i per tant s'ha de comparar amb un BETWEEN només de dates.
// Mantenir aquest helper separat de getMonthBoundaryStrings deixa explícit
// que els dos formats responen a tipus de columna diferents.
function getMonthDateBoundaryStrings(year, month) {
  const lastDay = lastDayOfMonth(year, month);
  return {
    startDate: `${pad4(year)}-${pad2(month)}-01`,
    endDate: `${pad4(year)}-${pad2(month)}-${pad2(lastDay)}`,
  };
}

// Retorna els límits del mes anterior al donat. S'utilitza per consultar
// la plantilla del mes passat i evitar repetir el mateix tipus de repte
// dos mesos seguits quan hi ha més d'un tipus disponible.
function getPreviousYearMonth(year, month) {
  if (month === 1) {
    return { year: year - 1, month: 12 };
  }
  return { year, month: month - 1 };
}

// Composa una cadena 'YYYY-MM-DD HH:MM:SS' amb els camps zero-padded.
// És l'únic format que s'envia a MySQL per a DATETIME des d'aquest mòdul,
// així garantim que mai depenem de la representació local d'un Date.
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
