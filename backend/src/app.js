const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Importar middleware
const {
  validationErrorHandler,
  dbErrorHandler,
  errorHandler,
  notFoundHandler
} = require('./middleware/errorHandler');

// Importar routes
const authRoutes = require('./routes/auth.routes');
const cimsRoutes = require('./routes/cims.routes');
const ascensionsRoutes = require('./routes/ascensions.routes');
const estatsRoutes = require('./routes/estats.routes');

// Crear aplicació Express
const app = express();

// Configurar CORS
const corsOptions = {
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true,
  optionsSuccessStatus: 200
};

// Middleware globals
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging de requests en desenvolupament
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`);
    next();
  });
}

// Ruta de salut (health check)
app.get('/', (req, res) => {
  res.json({
    message: 'API CiMS - Rutas de Muntanya',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      auth: '/api/auth',
      cims: '/api/cims',
      ascensions: '/api/ascensions',
      estats: '/api/estats'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString()
  });
});

// Routes de l'API
app.use('/api/auth', authRoutes);
app.use('/api/cims', cimsRoutes);
app.use('/api/ascensions', ascensionsRoutes);
app.use('/api/estats', estatsRoutes);

// Middleware de gestió d'errors
app.use(validationErrorHandler);
app.use(dbErrorHandler);
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
