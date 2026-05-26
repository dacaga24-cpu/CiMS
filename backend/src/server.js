// Aquest fitxer és el punt d’inici del backend.
// Carrega la configuració, arrenca el servidor i comprova la connexió amb la base de dades.
require('dotenv').config();

const app = require('./app');
const testDb = require('./config/testDb');
const PasswordResetModel = require('./models/passwordResetModel');

// Aquest valor defineix el port on escoltarà el servidor.
// En producció pot venir de l’entorn, i en local s’utilitza 8080 per defecte.
const PORT = process.env.PORT || 8080;

// Defineix cada quant temps es netegen els tokens de recuperació caducats o utilitzats.
// Aquesta neteja evita acumular registres que ja no tenen valor funcional.
const TOKEN_CLEANUP_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 hores

// Aquest mètode elimina tokens de recuperació que ja no són vàlids.
// Si la neteja falla, registra l’error sense aturar el servidor.
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

// Aquest bloc posa en marxa el servidor.
// Després d’arrencar, comprova la connexió amb la base de dades i programa la neteja periòdica.
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);

  try {
    await testDb();
  } catch (error) {
    console.error('Database connection test failed:', error.message);
  }

  // La primera neteja s’executa en arrencar i després es repeteix cada dia.
  // El temporitzador no manté viu el procés si la plataforma decideix aturar-lo.
  await cleanupExpiredResetTokens();
  setInterval(cleanupExpiredResetTokens, TOKEN_CLEANUP_INTERVAL_MS).unref();
});