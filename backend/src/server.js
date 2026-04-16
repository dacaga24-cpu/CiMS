// Aquest fitxer és el punt d’inici del backend.
// La seva funció és carregar la configuració necessària, posar en marxa el servidor
// i comprovar si la connexió amb la base de dades està disponible.
require('dotenv').config();

const app = require('./app');
const testDb = require('./config/testDb');

// Aquest valor defineix en quin port escoltarà el servidor.
// A Cloud Run el port arriba per variable d’entorn, i si no existeix
// es fa servir 8080 com a valor per defecte.
const PORT = process.env.PORT || 8080;

// Aquest bloc posa en marxa el servidor i mostra per consola que ja està actiu.
// Just després, es fa una comprovació de la base de dades per validar que la connexió respon correctament.
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);

    try {
    await testDb();
  } catch (error) {
    console.error('Database connection test failed:', error.message);
  }
});