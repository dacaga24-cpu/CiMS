// Protegeix les rutes privades: valida el JWT i posa req.userId si tot va bé.
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

    if (!authHeader) {
      const error = new Error('No token provided');
      error.statusCode = 401;
      throw error;
    }

    // Es valida que la capçalera tingui exactament dues parts ("Bearer" i el
    // token), perquè variants amb espais extra o esquemes diferents no passin
    // la validació de manera silenciosa.
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
      const error = new Error('Invalid authorization header format');
      error.statusCode = 401;
      throw error;
    }

    const token = parts[1];
    const decoded = jwt.verify(token, secret);

    req.userId = decoded.userId;
    next();
  } catch (error) {
    // Adapta els errors d'autenticació a respostes coherents.
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
