// Aquest fitxer prepara la configuració general del servidor.
// Aquí es defineixen els elements comuns que s’aplicaran a totes les peticions
// i es connecten les rutes principals amb l’aplicació.

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const peakRoutes = require('./routes/peakRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Aquest bloc activa els comportaments bàsics que necessita el servidor
// per rebre peticions externes i interpretar correctament les dades en format JSON.
app.use(cors()); // Permet que l’aplicació client es pugui comunicar amb el backend des d’un altre origen.
app.use(express.json()); // Converteix el contingut JSON de les peticions en objectes que el servidor pot utilitzar.

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

// Aquest bloc registra les rutes relacionades amb la recuperació de contrasenya.
// Es manté el prefix /reset-password per diferenciar clarament aquesta funcionalitat de les altres rutes d’API.
app.use('/reset-password', require('./routes/resetPasswordRoute'));

// Aquest gestor s’aplica al final perquè pugui recollir qualsevol error
// produït durant el recorregut d’una petició.
app.use(errorHandler);

module.exports = app;
