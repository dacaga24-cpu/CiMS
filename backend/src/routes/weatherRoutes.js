// Aquest fitxer defineix les rutes meteorològiques associades als cims.
// Les rutes requereixen autenticació perquè consulten un servei extern amb quota limitada.
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { weatherRateLimiter } = require('../middleware/rateLimiters');
const WeatherController = require('../controllers/weatherController');

// Aquests middlewares protegeixen les rutes abans de consultar la previsió.
// Primer es valida la sessió i després es limita el nombre de peticions meteorològiques.
router.use(authMiddleware);
router.use(weatherRateLimiter);

// Retorna la previsió diària d’un cim.
// El nombre de dies es pot ajustar amb la query string.
router.get('/peaks/:peakId/weather/daily', WeatherController.getPeakDaily);

// Retorna la previsió horària d’un cim per a una data concreta.
// Aquesta ruta permet mostrar una visió més detallada del temps disponible.
router.get('/peaks/:peakId/weather/hourly', WeatherController.getPeakHourly);

module.exports = router;