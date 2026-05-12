// Aquest fitxer prepara la configuració general del servidor.
// Aquí es defineixen els elements comuns que s’aplicaran a totes les peticions
// i es connecten les rutes principals amb l’aplicació.

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

// En entorns com Cloud Run el servidor rep les peticions a través d'un proxy,
// de manera que per defecte req.ip seria sempre la IP interna del proxy.
// Habilitant la confiança en un nivell de proxy, Express llegeix l'IP real
// del client des de la capçalera X-Forwarded-For, cosa imprescindible perquè
// els limitadors de peticions puguin aplicar límits per usuari i no de manera global.
app.set('trust proxy', 1);

// Aquest middleware afegeix capçaleres HTTP defensives per defecte,
// com ara X-Content-Type-Options, X-Frame-Options i Strict-Transport-Security.
// Són especialment rellevants per la pàgina HTML del restabliment de contrasenya,
// que el mateix backend serveix al navegador.
app.use(helmet());

// Aquest bloc activa els comportaments bàsics que necessita el servidor
// per rebre peticions externes i interpretar correctament les dades en format JSON.
//
// El CORS està restringit a una llista blanca d'orígens. Només els navegadors
// que carreguen el frontend des d'una d'aquestes adreces poden llegir les
// respostes de l'API. Altres orígens (com una web maliciosa que intenti
// aprofitar la sessió de l'usuari) es queden amb la petició bloquejada al
// navegador. Això NO protegeix contra peticions sense origen com curl o apps
// mòbils, ja que el CORS només l'aplica el navegador.
//
// FRONTEND_URL és l'URL del frontend de producció (Firebase Hosting).
// CORS_DEV_ORIGINS permet afegir orígens addicionals separats per coma per a
// desenvolupament local (per exemple http://localhost:8080 per a Flutter web).
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
      // Les peticions sense capçalera Origin (curl, apps mòbils, server-to-server)
      // no estan subjectes a CORS i es deixen passar perquè la protecció afecta
      // només els navegadors web.
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

// Es limita la mida màxima del cos JSON a 10kb perquè cap endpoint de l'API
// necessita rebre més dades que això (credencials, filtres i tokens són petits).
// D'aquesta manera s'evita que una petició amb un cos molt gran pugui consumir
// memòria o CPU del servidor i convertir-se en un vector d'atac senzill.
app.use(express.json({ limit: '10kb' })); // Converteix el contingut JSON de les peticions en objectes que el servidor pot utilitzar.

// Aquest endpoint senzill serveix per comprovar si el servidor està en funcionament.
// És útil per validar ràpidament que l’aplicació ha arrencat correctament.
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Aquest bloc registra les rutes d’autenticació sota un prefix comú.
// Això ajuda a mantenir organitzats els endpoints relacionats amb usuaris i accés.
app.use('/api/auth', authRoutes);

// Aquest bloc registra les rutes del catàleg de cims.
// Es manté el mateix patró de prefix /api per agrupar tota l'API.
app.use('/api/peaks', peakRoutes);

// Aquest bloc registra les rutes relacionades amb l'estat dels cims.
// Es manté el prefix /api per coherència amb la resta de l'API.
app.use('/api/peak-status', peakStatusRoutes);

// Aquest bloc registra les rutes relacionades amb les ascensions registrades
// pels usuaris. Totes les rutes estan protegides amb autenticació JWT.
app.use('/api/ascents', ascentRoutes);

// Aquest bloc registra l'endpoint d'estadístiques personals de l'usuari.
// La pantalla d'estadístiques en consumeix les dades amb una sola crida.
app.use('/api/stats', statsRoutes);

// Aquest bloc registra l'endpoint del dashboard. La pantalla d'inici fa una
// única crida i rep el repte, els objectius pendents, els preferits i la
// sèrie mensual ja preparats per pintar la UI.
app.use('/api/dashboard', dashboardRoutes);

// Aquest bloc registra l'endpoint del repte mensual. La plantilla del mes
// es genera de manera "lazy" la primera vegada que es consulta o quan un
// usuari registra una ascensió dins del mes en curs.
app.use('/api/monthly-challenges', monthlyChallengeRoutes);

// Aquest bloc registra el recurs ascent-photos. Exposa la generació de
// signed URLs perquè el frontend pugui pujar fotos directament al bucket
// de GCS abans de confirmar la creació de l'ascens.
app.use('/api/ascent-photos', ascentPhotoRoutes);

// Aquest bloc registra les rutes de les comarques.
// Serveix per alimentar els filtres territorials del catàleg al frontend.
app.use('/api/regions', regionRoutes);

// Aquest bloc registra els endpoints meteorològics. Es monten directament
// sota /api perquè les rutes finals viuen sota /api/peaks/:peakId/weather i
// /api/regions/:regionId/weather: així s'agrupen amb el recurs natural
// (cim o comarca) sense barrejar-se amb peakRoutes ni regionRoutes, que
// són públics i no han de quedar afectats pel rate limiter de Weather.
app.use('/api', weatherRoutes);

// Aquest bloc registra les rutes relacionades amb la recuperació de contrasenya.
// Es manté el prefix /reset-password per diferenciar clarament aquesta funcionalitat de les altres rutes d’API.
app.use('/reset-password', resetPasswordRoutes);

// Aquest bloc registra les rutes relacionades amb la gestió d'usuaris (perfil, preferències, etc.).
// Totes les rutes d'aquest grup estan protegides amb autenticació JWT perquè només l'usuari propietari del compte pugui accedir-hi.
app.use('/api/users', userRoutes);

// Aquest gestor s’aplica al final perquè pugui recollir qualsevol error
// produït durant el recorregut d’una petició.
app.use(errorHandler);

module.exports = app;
