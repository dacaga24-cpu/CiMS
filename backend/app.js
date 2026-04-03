// app.js
// Responsabilidad: Configuracion de Express — middlewares globales y registro de rutas.
// NO contiene logica de negocio ni definiciones de endpoints individuales.

const express = require('express');
const cors = require('cors');

const authRoutes = require('./src/routes/authRoutes');
const errorHandler = require('./src/middleware/errorHandler');

const app = express();

// Middlewares globales
app.use(cors());
app.use(express.json());

// Health check — unico endpoint con codigo real (verificacion de arranque)
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Registro de rutas
app.use('/api/auth', authRoutes);

// Manejador global de errores (debe ir al final)
app.use(errorHandler);

module.exports = app;
