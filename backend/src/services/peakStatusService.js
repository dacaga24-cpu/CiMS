const PeakStatusModel = require('../models/peakStatusModel');
const { badRequest, requireInteger } = require('../utils/validation');

// Aquest servei centralitza la lògica de l'estat personal dels cims per a cada usuari.
// Aquí es validen els identificadors rebuts, es coordina la lògica d'upsert
// i es gestionen els casos on el recurs sol·licitat no existeix.
const PeakStatusService = {

  // Aquest mètode retorna l'estat d'un cim concret per a l'usuari autenticat.
  // Si encara no existeix cap registre per a la parella usuari-cim,
  // es llança un error 404 perquè el client distingeixi clarament els casos
  // d'identificador invàlid (400) i de recurs inexistent (404).
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

  // Aquest mètode retorna tots els estats que l'usuari autenticat té registrats.
  // Si no té cap estat creat, retorna una llista buida sense llançar cap error,
  // ja que és un resultat vàlid per a un usuari que encara no ha interaccionat amb cap cim.
  async getStatusByUser(userId) {
    return PeakStatusModel.findAllByUserId(userId);
  },

  // Aquest mètode crea o actualitza l'estat d'un cim per a l'usuari autenticat.
  // Si ja existeix un registre per a la parella usuari-cim, s'actualitzen els flags rebuts.
  // Si no existeix, es crea un nou registre amb els flags indicats i els altres a zero.
  // Aquesta lògica d'upsert evita que el frontend hagi de gestionar dos endpoints
  // separats i garanteix que mai es creïn registres duplicats.
  async upsertPeakStatus(userId, peakId, { isCompleted, isTarget, isFavorite } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');

    // Aquest bloc valida que almenys s'hagi indicat un flag per modificar,
    // perquè una petició sense cap camp és ambigua i no hauria de persistir res.
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
      await PeakStatusModel.updateByUserAndPeak(userId, parsedPeakId, {
        isCompleted,
        isTarget,
        isFavorite,
      });

      // Es torna a llegir el registre actualitzat per retornar sempre
      // l'estat complet i consistent des del servei, independentment
      // de quants camps s'hagin modificat en aquesta crida.
      return PeakStatusModel.findByUserAndPeak(userId, parsedPeakId);
    }

    return PeakStatusModel.create({
      userId,
      peakId: parsedPeakId,
      isCompleted: isCompleted ?? false,
      isTarget: isTarget ?? false,
      isFavorite: isFavorite ?? false,
    });
  },

  // Aquest mètode elimina l'estat d'un cim per a l'usuari autenticat.
  // Si no existia cap registre, es llança un error 404 perquè la resposta
  // reflecteixi que no hi havia res a eliminar.
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
