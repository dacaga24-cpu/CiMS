// Aquest fitxer és el punt d’inici del backend.
// La seva funció és carregar la configuració necessària, posar en marxa el servidor
// i comprovar si la connexió amb la base de dades està disponible.
require('dotenv').config();

const app = require('./app');
const testDb = require('./config/testDb');
const PasswordResetModel = require('./models/passwordResetModel');

// Aquest valor defineix en quin port escoltarà el servidor.
// A Cloud Run el port arriba per variable d’entorn, i si no existeix
// es fa servir 8080 com a valor per defecte.
const PORT = process.env.PORT || 8080;

// Periodicitat de la neteja de tokens de recuperació de contrasenya caducats.
// Sense aquesta neteja la taula password_reset_tokens creixeria indefinidament
// perquè els tokens utilitzats o caducats no s'esborren en cap altre flux.
const TOKEN_CLEANUP_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 hores

// Aquest mètode executa la neteja periòdica i registra els errors sense aturar
// el procés. Cloud Run reinicia instàncies sovint, per això la neteja s'executa
// també just després d'arrencar i no s'espera al primer interval.
async function cleanupExpiredResetTokens() {
  try {
    const removed = await PasswordResetModel.deleteExpired();
    if (removed > 0) {
      console.log(`Removed ${removed} expired or used password reset tokens`);
    }
  } catch (error) {
    console.error('Error cleaning up expired password reset tokens:', error.message);
  }
}

// Aquest bloc posa en marxa el servidor i mostra per consola que ja està actiu.
// Just després, es fa una comprovació de la base de dades per validar que la connexió respon correctament.
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);

  try {
    await testDb();
  } catch (error) {
    console.error('Database connection test failed:', error.message);
  }

  // Es fa una primera neteja en arrencar i s'agenda la repetició diària.
  // El timer no manté viu el procés (unref) perquè a Cloud Run el cicle de
  // vida l'imposa la plataforma i no volem allargar-lo per culpa del timer.
  await cleanupExpiredResetTokens();
  setInterval(cleanupExpiredResetTokens, TOKEN_CLEANUP_INTERVAL_MS).unref();
});
