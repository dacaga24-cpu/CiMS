// db.js
// Responsabilidad: Crear y exportar el pool de conexiones MySQL con mysql2.
// Lee las variables de entorno DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME.
// NO ejecuta queries — solo configura la conexion.

const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,   // Si no hi ha connexions lliures, espera en lloc de fallar
  connectionLimit: 10,        // Nombre màxim de connexions simultànies
  queueLimit: 0,              // 0 = sense límit de peticions en cua
});

module.exports = pool;