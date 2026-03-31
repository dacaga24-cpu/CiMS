// authMiddleware.js
// Responsabilidad: Verificar el JWT en el header Authorization de las peticiones protegidas.
// Extrae el token del header, lo verifica con jsonwebtoken, y anade el usuario decodificado a req.user.
// Si el token no es valido o no existe, responde con 401 Unauthorized.

// const jwt = require('jsonwebtoken');

// Middleware de autenticacion JWT
// Validara: presencia del header Authorization, formato Bearer <token>, firma y expiracion del JWT
function authMiddleware(req, res, next) {}

module.exports = authMiddleware;
