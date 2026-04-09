// Middleware global de gestió d’errors.
// Aquest fitxer s’encarrega de capturar els errors que arriben des dels controllers o serveis
// i convertir-los en una resposta HTTP adequada per al client.
const errorHandler = (err, req, res, next) => {
  // Si l’error porta un codi d’estat definit, l’utilitzem.
  // Si no en porta cap, assumim que és un error intern del servidor (500).
  const statusCode = err.statusCode || 500;

  // Aquí tractem específicament els errors d’autenticació que hem definit al projecte:
  // - 401: credencials incorrectes
  // - 409: conflicte, per exemple email ja registrat
  // En aquests casos retornem el missatge concret de l’error.
  if (statusCode === 401 || statusCode === 409) {
    return res.status(statusCode).json({
      error: err.message,
    });
  }

  // Si l’error no és un dels contemplats anteriorment,
  // el mostrem per consola perquè els desenvolupadors el puguin revisar.
  console.error(err.stack);
  
  // Retornem una resposta genèrica d’error intern.
  // Això evita exposar detalls tècnics innecessaris al client.
  return res.status(500).json({
    error: 'Internal Server Error',
  });
};

// Exportem el middleware perquè es pugui registrar a app.js
// i s’apliqui de forma global a tota l’aplicació.
module.exports = errorHandler;
