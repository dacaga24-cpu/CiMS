// Aquest fitxer centralitza la connexió amb la base de dades.
// Permet que tot el backend consulti i guardi dades amb una configuració comuna.
const mysql = require('mysql2/promise');

// Aquesta configuració defineix les dades bàsiques de connexió a MySQL.
// Les variables d’entorn permeten adaptar la connexió segons si l’aplicació s’executa en local o en producció.
// L’opció dateStrings conserva les dates simples en format YYYY-MM-DD per evitar canvis de dia causats per la zona horària.
const baseConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: ['DATE'],
};

const pool = mysql.createPool(
  process.env.INSTANCE_CONNECTION_NAME
    ? {
        ...baseConfig,
        socketPath: `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`,
      }
    : {
        ...baseConfig,
        host: process.env.DB_HOST || '127.0.0.1',
        port: process.env.DB_PORT || 3306,
      }
);

// Aquest export permet reutilitzar la mateixa connexió compartida des dels diferents mòduls del backend.
module.exports = pool;