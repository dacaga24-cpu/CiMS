// authMiddleware.js
// Responsabilidad: Verificar tokens JWT en rutes protegides
// Extrae el userId del token i l'adjunta a req.user

const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    // Obtenir el token del header Authorization
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const error = new Error('No token provided');
      error.statusCode = 401;
      throw error;
    }

    // Extreure el token (format: "Bearer <token>")
    const token = authHeader.substring(7);

    // Verificar el token
    const secret = process.env.JWT_SECRET;

    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }

    const decoded = jwt.verify(token, secret);

    // Adjuntar userId al request per a ús posterior
    req.userId = decoded.userId;

    next();
  } catch (error) {
    // Errors específics de JWT
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
