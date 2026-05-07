// Gestor d'errors centralitzat: converteix qualsevol error en una resposta
// HTTP coherent.
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;

  // 5xx: resposta genèrica per no exposar detalls interns.
  if (statusCode >= 500) {
    // En producció només es loga un missatge curt; els logs estructurats de
    // Cloud Run associen el registre a la petició sense filtrar info sensible.
    if (process.env.NODE_ENV === 'production') {
      console.error(`[error] ${req.method} ${req.originalUrl}: ${err.message}`);
    } else {
      console.error(err.stack);
    }
    return res.status(500).json({ error: 'Internal Server Error' });
  }

  // 4xx: missatge controlat directament al client.
  return res.status(statusCode).json({ error: err.message });
};

module.exports = errorHandler;
