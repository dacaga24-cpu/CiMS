// Aquest middleware llegeix el token JWT quan la petició en porta un.
// Permet enriquir algunes rutes amb dades de l’usuari sense exigir autenticació obligatòria.
const jwt = require('jsonwebtoken');

const optionalAuthMiddleware = (req, res, next) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    // Aquesta validació detecta una configuració incorrecta del servidor.
    // Sense el secret, no es poden verificar tokens de manera segura.
    const error = new Error('JWT_SECRET is not defined in environment variables');
    error.statusCode = 500;
    return next(error);
  }

  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return next();
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
    // Si la capçalera no té el format esperat, la petició continua sense usuari autenticat.
    return next();
  }

  try {
    const decoded = jwt.verify(parts[1], secret);
    // Aquesta comprovació assegura que el token conté un identificador d’usuari vàlid.
    // Si és correcte, es deixa disponible per als controladors que el necessitin.
    if (Number.isInteger(decoded.userId) && decoded.userId > 0) {
      req.userId = decoded.userId;
    }
  } catch (error) {
    // Els errors propis del token es tracten com una petició sense autenticació.
    // Altres errors es propaguen perquè puguin quedar registrats correctament.
    const isJwtError =
      error.name === 'JsonWebTokenError' ||
      error.name === 'TokenExpiredError' ||
      error.name === 'NotBeforeError';
    if (!isJwtError) {
      return next(error);
    }
  }

  next();
};

module.exports = optionalAuthMiddleware;