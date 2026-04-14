// Verifica tokens JWT en rutes protegides.
// Si el token és vàlid, adjunta req.userId per a ús posterior dels controllers.
const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    const error = new Error('JWT_SECRET is not defined in environment variables');
    error.statusCode = 500;
    return next(error);
  }

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const error = new Error('No token provided');
      error.statusCode = 401;
      throw error;
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, secret);

    req.userId = decoded.userId;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      error.message = 'Invalid token';
      error.statusCode = 401;
    } else if (error.name === 'TokenExpiredError') {
      error.message = 'Token expired';
      error.statusCode = 401;
    } else if (!error.statusCode) {
      error.statusCode = 401;
    }
    next(error);
  }
};

module.exports = authMiddleware;
