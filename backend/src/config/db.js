// Connexió compartida amb MySQL.
const mysql = require('mysql2/promise');

// Pool reutilitzable amb config per env vars.
//
// dateStrings: ['DATE'] fa que les columnes DATE es retornin com a 'YYYY-MM-DD'
// strings, no Date. Sense això, el driver les interpretava amb la timezone
// local del servidor i el client rebia un timestamp ISO desplaçat de dia.
// Les columnes DATETIME (created_at, updated_at) segueixen sent Date.
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

module.exports = pool;
