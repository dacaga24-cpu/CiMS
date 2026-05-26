// Aquest fitxer prepara la configuració general del servidor.
// Defineix middlewares comuns, rutes principals i gestió final d’errors.
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
const weatherRoutes = require('./routes/weatherRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Aquesta configuració permet identificar millor la IP real del client en entorns amb proxy.
// És important perquè els limitadors de peticions funcionin correctament.
app.set('trust proxy', 1);

// Aquest middleware afegeix capçaleres de seguretat a les respostes.
// Ajuda a protegir l’API i les pàgines HTML servides pel backend.
app.use(helmet());

// Aquest bloc defineix els orígens autoritzats per accedir a l’API des del navegador.
// Permet separar l’origen de producció dels orígens de desenvolupament.
const allowedOrigins = [
  process.env.FRONTEND_URL,
  ...(process.env.CORS_DEV_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
].filter(Boolean);

// Aquest middleware controla quins frontends poden llegir les respostes de l’API.
// Les peticions sense origen, com apps mòbils o eines de servidor, es deixen passar.
app.use(
  cors({
    origin: (origin, callback) => {
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

// Aquest middleware permet interpretar el cos JSON de les peticions.
// El límit evita rebre càrregues massa grans en endpoints que només necessiten dades petites.
app.use(express.json({ limit: '10kb' }));

// Aquest endpoint permet comprovar ràpidament si el servidor està actiu.
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Registra les rutes d’autenticació i accés al perfil bàsic.
app.use('/api/auth', authRoutes);

// Registra les rutes del catàleg de cims.
app.use('/api/peaks', peakRoutes);

// Registra les rutes de l’estat personal dels cims.
app.use('/api/peak-status', peakStatusRoutes);

// Registra les rutes d’ascensions dels usuaris.
app.use('/api/ascents', ascentRoutes);

// Registra les rutes d’estadístiques personals.
app.use('/api/stats', statsRoutes);

// Registra les rutes del dashboard principal.
app.use('/api/dashboard', dashboardRoutes);

// Registra les rutes del repte mensual.
app.use('/api/monthly-challenges', monthlyChallengeRoutes);

// Registra les rutes de fotos d’ascensions.
app.use('/api/ascent-photos', ascentPhotoRoutes);

// Registra les rutes de comarques.
app.use('/api/regions', regionRoutes);

// Registra les rutes meteorològiques associades als cims.
app.use('/api', weatherRoutes);

// Registra la pàgina de recuperació de contrasenya.
app.use('/reset-password', resetPasswordRoutes);

// Registra les rutes de perfil i gestió del compte d’usuari.
app.use('/api/users', userRoutes);

// Aquest gestor d’errors s’aplica al final.
// Recull qualsevol error produït durant el recorregut d’una petició.
app.use(errorHandler);

module.exports = app;