// Aquest fitxer defineix les rutes meteorològiques de CiMS. Totes
// estan protegides amb autenticació JWT perquè el cost de cada petició
// (quan no troba resposta a la cache) es tradueix en una crida a la
// Google Weather API, i exposar aquests endpoints anònimament permetria
// a un tercer esgotar la quota compartida fàcilment.
//
// Les rutes es declaren amb el prefix complet '/peaks/:peakId/weather/...'
// perquè el mòdul es monta a /api directament i així aprofitem la
// jerarquia natural de les URL (la previsió "pertany" al cim) sense
// barrejar-les amb peakRoutes, que té un règim d'autenticació diferent
// (públic).
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
// per defecte 7. Internament es demana sempre l'horitzó màxim i es
// retalla, perquè diferents valors de days comparteixen cache.
router.get('/peaks/:peakId/weather/daily', WeatherController.getPeakDaily);

// Previsió horària per cim, filtrada per la data sol·licitada. Sempre
// es demanen les 240h màximes a Google i es filtra al servei, així la
// mateixa cache serveix per a qualsevol dia dins el rang disponible.
router.get('/peaks/:peakId/weather/hourly', WeatherController.getPeakHourly);

module.exports = router;
