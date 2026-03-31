// peakService.js
// Responsabilidad: Logica de negocio relacionada con los cims.
// Coordina con el modelo Peak.
// NO accede a req/res — no sabe que existe HTTP.

const Peak = require('../models/Peak');

// Devuelve todos los cims, opcionalmente con filtros
async function getAllPeaks() {}

// Devuelve un cim por su ID, lanza error si no existe
async function getPeakById(id) {}

// Devuelve los cims de una comarca
async function getPeaksByRegion(regionId) {}

// Devuelve los cims filtrados por rango de altitud
async function getPeaksByAltitude(minAltitude, maxAltitude) {}

// Busca cims por nombre (busqueda parcial)
async function searchPeaks(query) {}

module.exports = { getAllPeaks, getPeakById, getPeaksByRegion, getPeaksByAltitude, searchPeaks };
