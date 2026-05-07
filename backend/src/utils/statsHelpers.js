// Utilitats compartides entre statsService i dashboardService.

// Construeix la sèrie mensual sencera a partir de la resposta agregada.
// La query SQL només retorna mesos amb activitat real; aquí s'omplen amb
// zero els que falten perquè el client rebi un array de mida fixa, ordenat
// cronològicament i sense forats lògics.
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
