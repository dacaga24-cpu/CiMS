const PeakStatusModel = require('../models/peakStatusModel');
const { badRequest, requireInteger } = require('../utils/validation');

// Estat "buit" (cap flag actiu). S'usa per respondre quan el client desactiva
// l'últim flag i el registre s'ha eliminat, així el frontend pot actualitzar
// la UI sense un GET addicional.
function emptyStatus(userId, peakId) {
  return {
    user_id: userId,
    peak_id: peakId,
    is_completed: 0,
    is_target: 0,
    is_favorite: 0,
  };
}

// Lògica de l'estat personal dels cims per a cada usuari.
const PeakStatusService = {

  // Estat d'un cim per a l'usuari autenticat. 404 si no existeix encara cap
  // registre per a la parella, perquè el client distingeixi clarament 400
  // (id invàlid) de 404 (recurs inexistent).
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

  // Tots els estats que l'usuari té registrats. Llista buida si no n'ha
  // creat cap (resultat vàlid).
  async getStatusByUser(userId) {
    return PeakStatusModel.findAllByUserId(userId);
  },

  // Crea o actualitza l'estat d'un cim. Upsert intern perquè el frontend no
  // hagi de gestionar dos endpoints i mai es creïn registres duplicats.
  async upsertPeakStatus(userId, peakId, { isCompleted, isTarget, isFavorite } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');

    // Almenys un flag és obligatori: una petició sense cap és ambigua.
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
      // Es calculen els flags finals per detectar abans d'escriure si quedaria
      // un registre "tot zero" — i en aquest cas, eliminar-lo enlloc de
      // mantenir una fila buida acumulant brossa.
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

      // Es rellegeix per retornar sempre l'estat complet i consistent.
      return PeakStatusModel.findByUserAndPeak(userId, parsedPeakId);
    }

    // No hi havia registre i la petició no marca cap flag a true: no té
    // sentit crear un registre buit; resposta neutra sense embrutar la BD.
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

  // Elimina l'estat d'un cim. 404 si no existia.
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
