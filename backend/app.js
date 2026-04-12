// Configuració d'Express — middlewares globals i registre de rutes.
// NO conté lògica de negoci ni definicions d'endpoints individuals.

const express = require('express');
const cors = require('cors');

const authRoutes = require('./src/routes/authRoutes');
const errorHandler = require('./src/middleware/errorHandler');

const app = express();

// Middlewares globals
app.use(cors()); // Permet peticions des d'altres dominis (Flutter)
app.use(express.json()); // Converteix el body de les peticions JSON a objectes JavaScript

// Health check — únic endpoint amb codi real (verificació d'arrencada)
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Registre de rutes
app.use('/api/auth', authRoutes);

// Gestor global d'errors (ha d'anar al final)
app.use(errorHandler);

module.exports = app;
