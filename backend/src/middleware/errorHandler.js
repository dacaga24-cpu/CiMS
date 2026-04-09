const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;

  if (statusCode === 401 || statusCode === 409) {
    return res.status(statusCode).json({
      error: err.message,
    });
  }

  console.error(err.stack);
  
  return res.status(500).json({
    error: 'Internal Server Error',
  });
};

module.exports = errorHandler;
