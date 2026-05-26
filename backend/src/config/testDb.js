// Aquest fitxer permet comprovar la connexió amb la base de dades.
// És útil per detectar problemes de configuració en iniciar el backend.
const pool = require('./db');

// Aquest mètode prova si MySQL és accessible amb la configuració actual.
// Si la connexió funciona, l’allibera perquè pugui continuar sent reutilitzada pel backend.
async function testDbConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('MySQL connection OK');
    connection.release();
  } catch (error) {
    console.error('MySQL connection error:', error.message);
  }
}

// Aquest export permet executar la comprovació durant l’arrencada del servidor.
module.exports = testDbConnection;