  // Aquest middleware centralitza la gestió d’errors del backend.
  // La seva funció és convertir qualsevol error detectat durant una petició
  // en una resposta HTTP clara i coherent per al client.                                                                                                                      
  const errorHandler = (err, req, res, next) => {                                                                                                                                             
    const statusCode = err.statusCode || 500;           

    // Aquest bloc diferencia els errors interns dels errors controlats.
    // Si el problema és greu o no s’ha definit cap codi concret, es retorna una resposta genèrica
    // per evitar exposar detalls interns de l’aplicació.                                                                                                                                                                                          
    if (statusCode >= 500) {                                      
      console.error(err.stack);                                                                                                                                                               
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    // Si l’error ja estava previst i té un codi concret, es retorna aquest codi
    // juntament amb el missatge corresponent perquè el client pugui gestionar-lo.    
    return res.status(statusCode).json({ error: err.message });                                                                                                                               
  };
  
  // Aquest export permet utilitzar aquest gestor d’errors com a pas final
  // dins del flux de peticions del servidor.
  module.exports = errorHandler;    
