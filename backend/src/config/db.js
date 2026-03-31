const mysql = require('mysql2/promise');
require('dotenv').config();

// Configuració del pool de connexions
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'bemen3',
  database: process.env.DB_NAME || 'cims_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

// Verificar la connexió
const testConnection = async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Connexió a MySQL establerta correctament');
    connection.release();
  } catch (error) {
    console.error('❌ Error connectant a MySQL:', error.message);
    process.exit(1);
  }
};

module.exports = { pool, testConnection };
