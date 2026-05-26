// Aquest middleware centralitza la gestió d’errors del backend.
// Converteix els errors de l’aplicació en respostes HTTP coherents per al client.
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;

  // Aquest bloc gestiona els errors interns no controlats.
  // Retorna una resposta genèrica per protegir els detalls interns de l’aplicació.
  if (statusCode >= 500 && !err.code) {
    // El registre de l’error s’adapta segons l’entorn.
    // En producció es mostra menys detall per evitar exposar informació sensible.
    if (process.env.NODE_ENV === 'production') {
      console.error(`[error] ${req.method} ${req.originalUrl}: ${err.message}`);
    } else {
      console.error(err.stack);
    }
    return res.status(500).json({ error: 'Internal Server Error' });
  }

  // Aquest bloc registra errors controlats del servidor.
  // Permet conservar informació útil per investigar incidències sense enviar detalls interns al client.
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

// Aquest export permet utilitzar el gestor d’errors com a pas final del flux de peticions.
module.exports = errorHandler;