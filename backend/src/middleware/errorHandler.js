// Middleware per gestionar errors de validació
const validationErrorHandler = (err, req, res, next) => {
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Error de validació',
      details: err.errors
    });
  }
  next(err);
};

// Middleware per gestionar errors de base de dades
const dbErrorHandler = (err, req, res, next) => {
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      error: 'Conflicte',
      message: 'Aquest registre ja existeix'
    });
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(404).json({
      error: 'No trobat',
      message: 'Referència no trobada a la base de dades'
    });
  }

  next(err);
};

// Middleware general per gestionar errors
const errorHandler = (err, req, res, next) => {
  console.error('❌ Error:', err);

  // Error personalitzat amb status
  if (err.status) {
    return res.status(err.status).json({
      error: err.message || 'Error del servidor'
    });
  }

  // Error 404 - no trobat
  if (err.message === 'Not Found') {
    return res.status(404).json({
      error: 'Recurs no trobat',
      path: req.path
    });
  }

  // Error genèric del servidor
  res.status(500).json({
    error: 'Error intern del servidor',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Alguna cosa ha anat malament'
  });
};

// Middleware per rutes no trobades (404)
const notFoundHandler = (req, res) => {
  res.status(404).json({
    error: 'Ruta no trobada',
    path: req.path,
    method: req.method
  });
};

module.exports = {
  validationErrorHandler,
  dbErrorHandler,
  errorHandler,
  notFoundHandler
};
