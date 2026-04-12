// Punt d'entrada de l'aplicació.
// Carrega les variables d'entorn, arrenca el servidor HTTP
// i verifica la connexió amb la base de dades.
const app = require('./app');
const testDb = require('./src/config/testDb');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

// Inicia el servidor i comprova que la base de dades és accessible.
// Si la connexió falla, el servidor arrenca igualment però mostra l'error per consola.
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await testDb();
});
