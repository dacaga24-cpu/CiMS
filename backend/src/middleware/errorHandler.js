  // ── INICIO errorHandler.js ──
  // Middleware global de gestió d'errors.                                                                                                                                                    
  // Respecta qualsevol err.statusCode definit pels serveis/controllers.                                                                                                                      
  // Només cau a un 500 genèric quan no hi ha statusCode o és >= 500.                                                                                                                         
  const errorHandler = (err, req, res, next) => {                                                                                                                                             
    const statusCode = err.statusCode || 500;                                                                                                                                                 
                                                                                                                                                                                              
    if (statusCode >= 500) {                                      
      console.error(err.stack);                                                                                                                                                               
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    return res.status(statusCode).json({ error: err.message });                                                                                                                               
  };
                                                                                                                                                                                              
  module.exports = errorHandler;    
