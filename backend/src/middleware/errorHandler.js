// errorHandler.js
// Responsabilidad: Manejador global de errores de Express.
// Centraliza todos los errores no capturados por los controladores.
// Registra el error en consola y devuelve una respuesta JSON estandarizada.

// Manejador global de errores (4 parametros obligatorios para que Express lo reconozca)
function errorHandler(err, req, res, next) {}

module.exports = errorHandler;
