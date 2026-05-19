// Aquest middleware centralitza la gestió d’errors del backend.
// La seva funció és convertir qualsevol error detectat durant una petició
// en una resposta HTTP clara i coherent per al client.
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;

  // Aquest bloc diferencia els errors interns dels errors controlats.
  // Si el problema és greu i no porta un codi explícit, es retorna una
  // resposta genèrica per no exposar detalls interns de l’aplicació.
  // En canvi, si l'error porta `err.code` informat (per exemple,
  // WEATHER_PROVIDER_UNAVAILABLE), es considera un 5xx controlat:
  // ja sabem què ha fallat i volem que el client ho pugui distingir
  // d'un error realment intern, així que es propaguen missatge i codi
  // tal qual i es deixa el log al servidor amb prou context per
  // investigar-ho.
  if (statusCode >= 500 && !err.code) {
    // El stack trace només es registra fora de producció. A producció es deixa
    // un missatge curt amb el mètode i el path, perquè els logs estructurats
    // de Cloud Run associen aquest registre a la petició sense exposar
    // detalls interns que podrien filtrar informació sensible.
    if (process.env.NODE_ENV === 'production') {
      console.error(`[error] ${req.method} ${req.originalUrl}: ${err.message}`);
    } else {
      console.error(err.stack);
    }
    return res.status(500).json({ error: 'Internal Server Error' });
  }

  // Si l’error ja estava previst i té un codi concret, es retorna aquest
  // codi juntament amb el missatge corresponent perquè el client el
  // pugui gestionar. Per als 5xx amb codi (proveïdor extern caigut), a
  // més, es loguega l'incident al servidor amb el detall intern
  // (`internalDetail`) que sí pot contenir context operacional concret
  // —quota esgotada, clau invàlida, etc.— sense que aquest detall
  // viatgi al client.
  if (statusCode >= 500) {
    console.error(
      `[error] ${req.method} ${req.originalUrl}: ` +
        `code=${err.code} message=${err.message} ` +
        `internal=${err.internalDetail || 'n/a'}`
    );
  }

  const body = { error: err.message };
  if (err.code) {
    body.code = err.code;
  }
  return res.status(statusCode).json(body);
};

// Aquest export permet utilitzar aquest gestor d’errors com a pas final
// dins del flux de peticions del servidor.
module.exports = errorHandler;
