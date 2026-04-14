// Aquest fitxer prepara la connexió compartida amb la base de dades.
// La seva funció és centralitzar la configuració necessària perquè la resta
// del backend pugui consultar o guardar dades de manera consistent.
const mysql = require('mysql2/promise');

// Aquest bloc crea un conjunt de connexions reutilitzables a MySQL.
// Les dades de connexió es llegeixen des de les variables d’entorn,
// fet que permet adaptar la configuració segons l’entorn on s’executa l’aplicació.
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,   // Si en un moment donat no hi ha cap connexió disponible, el sistema espera abans de fallar.
  connectionLimit: 10,        // Defineix quantes connexions es poden mantenir obertes al mateix temps.
  queueLimit: 0,              // Permet acumular peticions en espera sense establir un límit fix.
});

// Aquest export permet que altres parts del backend reutilitzin la mateixa connexió compartida.
// Això facilita l’accés a la base de dades des de models, serveis o repositoris.
module.exports = pool;