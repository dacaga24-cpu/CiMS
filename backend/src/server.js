// Punt d'entrada del backend: arrenca el servidor i comprova la BD.
require('dotenv').config();

const app = require('./app');
const testDb = require('./config/testDb');
const PasswordResetModel = require('./models/passwordResetModel');

// A Cloud Run el port arriba per env; 8080 com a fallback local.
const PORT = process.env.PORT || 8080;

// Cada 24h. Sense aquesta neteja, password_reset_tokens creixeria
// indefinidament perquè els tokens utilitzats o caducats no s'esborren
// en cap altre flux.
const TOKEN_CLEANUP_INTERVAL_MS = 24 * 60 * 60 * 1000;

// Executa la neteja i loga errors sense aturar el procés.
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

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);

  try {
    await testDb();
  } catch (error) {
    console.error('Database connection test failed:', error.message);
  }

  // Primera neteja en arrencar i repetició diària. unref() perquè el timer
  // no allargui el cicle de vida del procés a Cloud Run.
  await cleanupExpiredResetTokens();
  setInterval(cleanupExpiredResetTokens, TOKEN_CLEANUP_INTERVAL_MS).unref();
});
