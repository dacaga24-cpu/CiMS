// Aquest fitxer protegeix les rutes que només poden utilitzar els usuaris autenticats.
// La seva funció és comprovar si la petició porta un token vàlid i, si és així,
// deixar preparada la informació bàsica de l’usuari per a la resta del procés.
const jwt = require('jsonwebtoken');

// Aquest mètode comprova l’autenticació abans que la petició arribi al controlador.
// Revisa si hi ha un token, valida que sigui correcte i, si tot va bé,
// guarda l’identificador de l’usuari a la petició perquè es pugui utilitzar més endavant.
const authMiddleware = (req, res, next) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    const error = new Error('JWT_SECRET is not defined in environment variables');
    error.statusCode = 500;
    return next(error);
  }

  try {
    const authHeader = req.headers.authorization;

    // Aquest bloc comprova que la petició inclogui un token d’accés
    // amb el format esperat per poder validar la sessió de l’usuari.
    // Es valida que la capçalera tingui exactament dues parts ("Bearer" i el
    // token) per evitar que variants amb espais extra o esquemes diferents
    // passin la validació de manera silenciosa.
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

    // Si el token és correcte, aquest valor identifica quin usuari
    // està fent la petició i permet que els controladors treballin amb el seu perfil.    
    req.userId = decoded.userId;
    next();
  } catch (error) {

    // Aquest bloc adapta els errors d’autenticació perquè la resposta sigui coherent
    // quan el token és invàlid, ha caducat o no s’ha pogut validar.
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
