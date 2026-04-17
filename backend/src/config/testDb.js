// Aquest fitxer comprova si l’aplicació pot connectar-se correctament a la base de dades.
// És rellevant perquè permet detectar des de l’inici si la configuració de MySQL és operativa.
const pool = require('./db');

// Aquest mètode intenta obtenir una connexió del conjunt compartit de connexions.
// Si ho aconsegueix, confirma que la connexió amb MySQL funciona i l’allibera perquè es pugui reutilitzar.
// Si falla, mostra l’error per consola per facilitar la detecció del problema en arrencar el servidor.
async function testDbConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('MySQL connection OK');
    connection.release();
  } catch (error) {
    console.error('MySQL connection error:', error.message);
  }
}

// Aquest export permet reutilitzar aquesta comprovació des d’altres punts del backend,
// habitualment durant l’arrencada del servidor.
module.exports = testDbConnection;