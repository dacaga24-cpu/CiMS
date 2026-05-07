// Comprova que la connexió amb MySQL funciona en arrencar el servidor.
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
