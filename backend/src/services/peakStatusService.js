const PeakStatusModel = require('../models/peakStatusModel');
const { badRequest, requireInteger } = require('../utils/validation');

// Aquest helper crea un estat neutre per a un cim sense marques actives.
// Manté una resposta estable perquè el frontend rebi sempre la mateixa estructura.
function emptyStatus(userId, peakId) {
  return {
    user_id: userId,
    peak_id: peakId,
    is_completed: 0,
    is_target: 0,
    is_favorite: 0,
    has_verified_ascent: 0,
  };
}

// Aquest servei centralitza la gestió de l’estat personal dels cims.
// Permet consultar, crear, actualitzar i eliminar marques com completat, objectiu o preferit.
const PeakStatusService = {

  // Retorna l’estat personal d’un cim concret per a l’usuari autenticat.
  // Si no hi ha cap registre guardat, retorna un error perquè el client pugui gestionar-ho.
  async getStatusByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');

    const status = await PeakStatusModel.findByUserAndPeak(userId, parsedPeakId);

    if (!status) {
      const error = new Error('Peak status not found');
      error.statusCode = 404;
      throw error;
    }

    return status;
  },

  // Retorna tots els estats personals de l’usuari autenticat.
  // Aquesta informació alimenta pantalles com el catàleg, el mapa i el detall del cim.
  async getStatusByUser(userId) {
    return PeakStatusModel.findAllByUserId(userId);
  },

  // Crea o actualitza l’estat personal d’un cim.
  // Només modifica les marques rebudes i evita guardar registres sense valor funcional.
  async upsertPeakStatus(userId, peakId, { isCompleted, isTarget, isFavorite } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');

    // Aquesta comprovació assegura que la petició indiqui almenys una marca a modificar.
    // Evita operacions que no aportarien cap canvi real.
    const hasAnyFlag =
      isCompleted !== undefined ||
      isTarget !== undefined ||
      isFavorite !== undefined;

    if (!hasAnyFlag) {
      throw badRequest(
        'At least one field is required: isCompleted, isTarget or isFavorite'
      );
    }

    const existing = await PeakStatusModel.findByUserAndPeak(userId, parsedPeakId);

    if (existing) {
      // Aquest bloc calcula l’estat final abans de guardar-lo.
      // Si totes les marques queden desactivades, elimina el registre i retorna un estat neutre.
      const finalCompleted = isCompleted !== undefined
        ? Boolean(isCompleted)
        : existing.is_completed === 1;
      const finalTarget = isTarget !== undefined
        ? Boolean(isTarget)
        : existing.is_target === 1;
      const finalFavorite = isFavorite !== undefined
        ? Boolean(isFavorite)
        : existing.is_favorite === 1;

      if (!finalCompleted && !finalTarget && !finalFavorite) {
        await PeakStatusModel.deleteByUserAndPeak(userId, parsedPeakId);
        return emptyStatus(userId, parsedPeakId);
      }

      await PeakStatusModel.updateByUserAndPeak(userId, parsedPeakId, {
        isCompleted,
        isTarget,
        isFavorite,
      });

      // Es torna a consultar l’estat per retornar una resposta completa i actualitzada.
      // També conserva informació derivada, com l’existència d’una ascensió verificada.
      return PeakStatusModel.findByUserAndPeak(userId, parsedPeakId);
    }

    // Si no existeix cap registre i cap marca queda activa, es retorna un estat neutre.
    // Això evita crear files innecessàries a la base de dades.
    if (!isCompleted && !isTarget && !isFavorite) {
      return emptyStatus(userId, parsedPeakId);
    }

    return PeakStatusModel.create({
      userId,
      peakId: parsedPeakId,
      isCompleted: isCompleted ?? false,
      isTarget: isTarget ?? false,
      isFavorite: isFavorite ?? false,
    });
  },

  // Elimina l’estat personal d’un cim.
  // Si no existia cap registre, retorna un error perquè el client pugui informar correctament.
  async removeByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');

    const affectedRows = await PeakStatusModel.deleteByUserAndPeak(userId, parsedPeakId);

    if (affectedRows === 0) {
      const error = new Error('Peak status not found');
      error.statusCode = 404;
      throw error;
    }
  },
};

module.exports = PeakStatusService;