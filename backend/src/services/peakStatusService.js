// peakStatusService.js
// Responsabilidad: Logica de negocio para gestionar el estado de los cims por usuario.
// Coordina con el modelo PeakStatus.
// NO accede a req/res — no sabe que existe HTTP.

const PeakStatus = require('../models/PeakStatus');

// Obtiene el estado de un cim para un usuario
async function getStatus(userId, peakId) {}

// Obtiene todos los estados de cims de un usuario (completados, favoritos, objetivos)
async function getUserStatuses(userId) {}

// Actualiza el estado de un cim para un usuario (favorito, objetivo, completado)
async function updateStatus(userId, peakId, { isCompleted, isTarget, isFavorite }) {}

module.exports = { getStatus, getUserStatuses, updateStatus };
