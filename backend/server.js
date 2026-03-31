// server.js
// Responsabilidad: Entry point de la aplicacion. Arranca el servidor HTTP.
// NO contiene logica de rutas ni middlewares — eso esta en app.js.

const app = require('./src/app');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`CiMS server running on port ${PORT}`);
});
