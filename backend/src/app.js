// Configuració general del servidor: middlewares globals i registre de rutes.

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const authRoutes = require('./routes/authRoutes');
const peakRoutes = require('./routes/peakRoutes');
const regionRoutes = require('./routes/regionRoutes');
const resetPasswordRoutes = require('./routes/resetPasswordRoutes');
const peakStatusRoutes = require('./routes/peakStatusRoutes');
const ascentRoutes = require('./routes/ascentRoutes');
const statsRoutes = require('./routes/statsRoutes');
const userRoutes = require('./routes/userRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const monthlyChallengeRoutes = require('./routes/monthlyChallengeRoutes');
const ascentPhotoRoutes = require('./routes/ascentPhotoRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Cloud Run encapsula les peticions per un proxy. Confiar-hi permet llegir la
// IP real (X-Forwarded-For) perquè els rate limiters apliquin per client i no
// globalment.
app.set('trust proxy', 1);

// Capçaleres HTTP defensives (X-Frame-Options, HSTS, etc.). Rellevants també
// per la pàgina HTML de restabliment de contrasenya que serveix el backend.
app.use(helmet());

// CORS amb whitelist per env (FRONTEND_URL + CORS_DEV_ORIGINS). Bloqueja
// navegadors d'orígens no permesos; peticions sense Origin (curl, apps mòbils)
// queden fora perquè és una protecció del navegador.
const allowedOrigins = [
  process.env.FRONTEND_URL,
  ...(process.env.CORS_DEV_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
].filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Peticions sense Origin (curl, apps mòbils, server-to-server) no apliquen CORS.
      if (!origin) {
        return callback(null, true);
      }
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  })
);

// Límit de 10kb al cos JSON: cap endpoint necessita més (credencials, filtres
// i tokens són petits) i evita peticions gegants com a vector de DoS.
app.use(express.json({ limit: '10kb' }));

// Health check per Cloud Run.
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Registre de rutes. El prefix /api agrupa l'API; /reset-password es manté fora
// perquè serveix una pàgina HTML al navegador, no JSON.
app.use('/api/auth', authRoutes);
app.use('/api/peaks', peakRoutes);
app.use('/api/peak-status', peakStatusRoutes);
app.use('/api/ascents', ascentRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/monthly-challenges', monthlyChallengeRoutes);
app.use('/api/ascent-photos', ascentPhotoRoutes);
app.use('/api/regions', regionRoutes);
app.use('/reset-password', resetPasswordRoutes);
app.use('/api/users', userRoutes);

// Gestor d'errors al final de la cadena: captura qualsevol error generat per
// les rutes anteriors.
app.use(errorHandler);

module.exports = app;
