// Aquest fitxer prepara la connexió compartida amb la base de dades.
// La seva funció és centralitzar la configuració necessària perquè la resta
// del backend pugui consultar o guardar dades de manera consistent.
const mysql = require('mysql2/promise');

// Aquest bloc crea un conjunt de connexions reutilitzables a MySQL.
// Les dades de connexió es llegeixen des de les variables d’entorn,
// fet que permet adaptar la configuració segons l’entorn on s’executa l’aplicació.
const pool = mysql.createPool(
  process.env.INSTANCE_CONNECTION_NAME
    ? {
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        socketPath: `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
      }
    : {
        host: process.env.DB_HOST || '127.0.0.1',
        port: process.env.DB_PORT || 3306,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
      }
);

// Aquest export permet que altres parts del backend reutilitzin la mateixa connexió compartida.
// Això facilita l’accés a la base de dades des de models, serveis o repositoris.
module.exports = pool;