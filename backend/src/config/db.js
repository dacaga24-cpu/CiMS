// Aquest fitxer prepara la connexió compartida amb la base de dades.
// La seva funció és centralitzar la configuració necessària perquè la resta
// del backend pugui consultar o guardar dades de manera consistent.
const mysql = require('mysql2/promise');

// Aquest bloc crea un conjunt de connexions reutilitzables a MySQL.
// Les dades de connexió es llegeixen des de les variables d’entorn,
// fet que permet adaptar la configuració segons l’entorn on s’executa l’aplicació.
//
// dateStrings: ['DATE'] fa que les columnes DATE es retornin com a cadenes
// 'YYYY-MM-DD' en lloc d'objectes Date. Sense aquesta opció, el driver
// interpretava el valor amb la timezone local del servidor i el client rebia
// un timestamp ISO com "2026-04-19T22:00:00.000Z" per una data emmagatzemada
// com a 2026-04-20, cosa que confondria el frontend i podria mostrar dates
// canviades de dia segons la timezone. Les columnes DATETIME (created_at,
// updated_at) segueixen sent Date i es serialitzen com a ISO amb hora.
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

// Aquest export permet que altres parts del backend reutilitzin la mateixa connexió compartida.
// Això facilita l’accés a la base de dades des de models, serveis o repositoris.
module.exports = pool;