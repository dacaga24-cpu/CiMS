const jwt = require('jsonwebtoken');

const authMiddleware = async (req, res, next) => {
  try {
    // Obtenir el token del header Authorization
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'No autoritzat',
        message: 'Token no proporcionat'
      });
    }

    const token = authHeader.split(' ')[1];

    // Verificar el token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Afegir les dades de l'usuari a la request
    req.user = {
      id: decoded.id,
      username: decoded.username,
      email: decoded.email
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expirat',
        message: 'Si us plau, inicia sessió de nou'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Token invàlid',
        message: 'Token no vàlid'
      });
    }

    return res.status(500).json({
      error: 'Error del servidor',
      message: error.message
    });
  }
};

// Middleware opcional - no falla si no hi ha token
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      req.user = {
        id: decoded.id,
        username: decoded.username,
        email: decoded.email
      };
    }

    next();
  } catch (error) {
    // Si hi ha error, continuar sense usuari autenticat
    next();
  }
};

module.exports = { authMiddleware, optionalAuth };
