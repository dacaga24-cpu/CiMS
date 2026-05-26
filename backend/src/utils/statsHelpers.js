// Aquest fitxer agrupa utilitats compartides per estadístiques i dashboard.
// Centralitza càlculs reutilitzables per evitar duplicar lògica entre serveis.

// Aquesta funció completa la sèrie dels últims mesos amb valors zero quan no hi ha activitat.
// Així el frontend rep sempre una llista estable i preparada per mostrar gràfics.
function fillMissingMonths(rawData, monthsBack) {
  const lookup = new Map();
  for (const entry of rawData) {
    lookup.set(`${entry.year}-${entry.month}`, entry.count);
  }

  const today = new Date();
  const result = [];
  for (let offset = monthsBack - 1; offset >= 0; offset -= 1) {
    const date = new Date(today.getFullYear(), today.getMonth() - offset, 1);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const count = lookup.get(`${year}-${month}`) ?? 0;
    result.push({ year, month, count });
  }
  return result;
}

module.exports = {
  fillMissingMonths,
};