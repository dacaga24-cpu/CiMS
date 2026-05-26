// Aquest fitxer protegeix les rutes reservades als usuaris autenticats.
// Valida el token rebut i prepara l’identificador de l’usuari per a la resta del backend.
const jwt = require('jsonwebtoken');

// Aquest middleware comprova que la petició tingui una sessió vàlida.
// Si el token és correcte, afegeix l’usuari autenticat a la petició.
const authMiddleware = (req, res, next) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    const error = new Error('JWT_SECRET is not defined in environment variables');
    error.statusCode = 500;
    return next(error);
  }

  try {
    const authHeader = req.headers.authorization;

    // Aquesta comprovació assegura que la petició inclogui un token amb el format esperat.
    // Això evita acceptar capçaleres incompletes o mal formades.
    if (!authHeader) {
      const error = new Error('No token provided');
      error.statusCode = 401;
      throw error;
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
      const error = new Error('Invalid authorization header format');
      error.statusCode = 401;
      throw error;
    }

    const token = parts[1];
    const decoded = jwt.verify(token, secret);

    // Aquest valor identifica l’usuari autenticat durant la resta de la petició.
    req.userId = decoded.userId;
    next();
  } catch (error) {

    // Aquest bloc normalitza els errors d’autenticació.
    // Permet retornar una resposta coherent quan el token és invàlid o ha caducat.
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