// Aquest fitxer és el punt d’inici del backend.
// La seva funció és carregar la configuració necessària, posar en marxa el servidor
// i comprovar si la connexió amb la base de dades està disponible.
require('dotenv').config();

const app = require('./app');
const testDb = require('./config/testDb');

// Aquest valor defineix en quin port escoltarà el servidor.
// Si no s’ha indicat cap port a la configuració, se n’utilitza un per defecte
const PORT = process.env.PORT || 3000;

// Aquest bloc posa en marxa el servidor i mostra per consola que ja està actiu.
// Just després, es fa una comprovació de la base de dades per validar que la connexió respon correctament.
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await testDb();
});