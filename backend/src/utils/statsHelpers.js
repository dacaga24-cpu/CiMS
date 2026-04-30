// Aquest fitxer agrupa les utilitats de composició compartides entre els
// serveis de stats i de dashboard. Centralitzar-ho aquí evita que el mateix
// codi (per exemple, el reompliment de mesos sense activitat) hagi d'existir
// duplicat a dos llocs i que un canvi al format hagués d'aplicar-se per
// separat a cada servei.

// Aquesta funció construeix la sèrie mensual sencera a partir de la resposta
// agregada del backend. La query SQL només retorna mesos amb activitat real,
// així que aquí es genera l'esquelet dels últims N mesos i s'omplen amb zero
// els que falten. El client rep sempre un array de mida fixa, ordenat
// cronològicament i sense forats lògics, cosa que simplifica la pintura del
// gràfic perquè no ha de calcular cap data ni omplir buits.
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
