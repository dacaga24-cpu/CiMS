// Aquest fitxer defineix les rutes meteorològiques de CiMS. Totes
// estan protegides amb autenticació JWT perquè el cost de cada petició
// (quan no troba resposta a la cache) es tradueix en una crida a la
// Google Weather API, i exposar aquests endpoints anònimament permetria
// a un tercer esgotar la quota compartida fàcilment.
//
// Les rutes es declaren amb el prefix complet ('/peaks/:peakId/weather/...'
// i '/regions/:regionId/weather/...') perquè el mòdul es monta a /api
// directament. Així aprofitem la jerarquia natural de les URL del
// frontend (la previsió "pertany" al cim o a la comarca) sense
// barrejar-les amb els routers de peakRoutes o regionRoutes, que tenen
// règims d'autenticació diferents.
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { weatherRateLimiter } = require('../middleware/rateLimiters');
const WeatherController = require('../controllers/weatherController');

// L'ordre dels middlewares és deliberat: primer es valida el token i
// després s'aplica el rate limiter. Així una pluja de peticions sense
// JWT vàlid és rebutjada amb 401 sense consumir el bucket de 60/15min,
// que queda reservat per a usuaris autenticats. El sostre s'aplica per
// IP (default d'express-rate-limit), no per userId: usuaris darrere
// d'una mateixa NAT poden limitar-se entre si, trade-off acceptable
// fins que calgui afinament per usuari.
router.use(authMiddleware);
router.use(weatherRateLimiter);

// Previsió diària per cim. La query string accepta ?days=N (1..10),
// per defecte 7. La cache es clava per cim+dies, de manera que demandes
// amb diferents horitzons tenen entrades independents.
router.get('/peaks/:peakId/weather/daily', WeatherController.getPeakDaily);

// Previsió horària per cim, filtrada per la data sol·licitada. Sempre
// es demanen les 240h màximes a Google i es filtra al servei, així la
// mateixa cache serveix per a qualsevol dia dins el rang disponible.
router.get('/peaks/:peakId/weather/hourly', WeatherController.getPeakHourly);

// Previsió agregada per comarca per a una data concreta. Aquesta ruta és
// la que utilitza el filtre per clima del catàleg i del mapa, però també
// es pot consumir directament en vistes que vulguin mostrar el clima
// d'una comarca sencera.
router.get('/regions/:regionId/weather/summary', WeatherController.getRegionSummary);

module.exports = router;
