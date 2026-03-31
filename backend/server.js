const app = require('./src/app');
const { testConnection } = require('./src/config/db');

const PORT = process.env.PORT || 3000;

// Funció per iniciar el servidor
const startServer = async () => {
  try {
    // Verificar connexió a la base de dades
    await testConnection();

    // Iniciar el servidor HTTP
    app.listen(PORT, () => {
      console.log('╔═══════════════════════════════════════╗');
      console.log('║                                       ║');
      console.log(`║   🚀 Servidor CiMS en marxa!         ║`);
      console.log('║                                       ║');
      console.log(`║   📍 Port: ${PORT}                       ║`);
      console.log(`║   🌍 Entorn: ${process.env.NODE_ENV || 'development'}              ║`);
      console.log(`║   📚 API Docs: http://localhost:${PORT}    ║`);
      console.log('║                                       ║');
      console.log('╚═══════════════════════════════════════╝');
    });
  } catch (error) {
    console.error('❌ Error iniciant el servidor:', error);
    process.exit(1);
  }
};

// Gestió de tancat graciós
process.on('SIGTERM', () => {
  console.log('👋 SIGTERM rebut. Tancant servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('👋 SIGINT rebut. Tancant servidor...');
  process.exit(0);
});

// Iniciar el servidor
startServer();
