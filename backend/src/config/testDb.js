// Funció que comprova si la connexió amb MySQL funciona.
// S'executa una vegada quan el servidor arrenca.
// Demana una connexió al pool, i si respon, la connexió és correcta.
// Si falla, mostra l'error per consola però no atura el servidor.
const pool = require('./db');

async function testDbConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('MySQL connection OK');
    connection.release();
  } catch (error) {
    console.error('MySQL connection error:', error.message);
  }
}

module.exports = testDbConnection;