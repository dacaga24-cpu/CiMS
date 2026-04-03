// db.js
// Responsabilidad: Crear y exportar el pool de conexiones MySQL con mysql2.
// Lee las variables de entorno DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME.
// NO ejecuta queries — solo configura la conexion.

const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = pool;