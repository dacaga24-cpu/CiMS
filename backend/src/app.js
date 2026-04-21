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
app.use(cors()); // Permet que l’aplicació client es pugui comunicar amb el backend des d’un altre origen.

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

// Aquest bloc registra les rutes de les comarques.
// Serveix per alimentar els filtres territorials del catàleg al frontend.
app.use('/api/regions', regionRoutes);

// Aquest bloc registra les rutes relacionades amb la recuperació de contrasenya.
// Es manté el prefix /reset-password per diferenciar clarament aquesta funcionalitat de les altres rutes d’API.
app.use('/reset-password', resetPasswordRoutes);

// Aquest gestor s’aplica al final perquè pugui recollir qualsevol error
// produït durant el recorregut d’una petició.
app.use(errorHandler);

module.exports = app;
