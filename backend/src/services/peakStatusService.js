const PeakStatusModel = require('../models/peakStatusModel');

// Aquest mètode crea un error de validació amb codi 400.
// S'utilitza quan l'identificador rebut no té un format vàlid.
function badRequest(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// Aquest mètode converteix un valor rebut en un enter positiu estrictament major que zero.
// Retorna null si el valor no es pot interpretar com un enter vàlid,
// i d'aquesta manera permet detectar identificadors mal formats.
function parsePositiveInteger(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    return null;
  }
  return parsed;
}

// Aquest servei centralitza la lògica de l'estat personal dels cims per a cada usuari.
// Aquí es validen els identificadors rebuts, es coordina la lògica d'upsert
// i es gestionen els casos on el recurs sol·licitat no existeix.
const PeakStatusService = {

  // Aquest mètode retorna l'estat d'un cim concret per a l'usuari autenticat.
  // Si encara no existeix cap registre per a la parella usuari-cim,
  // es retorna null perquè el controlador pugui respondre amb un 404 clar.
  async getByPeak(userId, peakId) {
    const parsedPeakId = parsePositiveInteger(peakId);
    if (!parsedPeakId) {
      throw badRequest('Invalid peakId: must be a positive integer');
    }

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
  async getAllByUser(userId) {
    return PeakStatusModel.findAllByUserId(userId);
  },

  // Aquest mètode crea o actualitza l'estat d'un cim per a l'usuari autenticat.
  // Si ja existeix un registre per a la parella usuari-cim, s'actualitzen els flags rebuts.
  // Si no existeix, es crea un nou registre amb els flags indicats i els altres a zero.
  // Aquesta lògica d'upsert evita que el frontend hagi de gestionar dos endpoints
  // separats i garanteix que mai es creïn registres duplicats.
  async upsert(userId, peakId, { isCompleted, isTarget, isFavorite } = {}) {
    const parsedPeakId = parsePositiveInteger(peakId);
    if (!parsedPeakId) {
      throw badRequest('Invalid peakId: must be a positive integer');
    }

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
      isCompleted: isCompleted ?? 0,
      isTarget: isTarget ?? 0,
      isFavorite: isFavorite ?? 0,
    });
  },

  // Aquest mètode elimina l'estat d'un cim per a l'usuari autenticat.
  // Si no existia cap registre, es llança un error 404 perquè la resposta
  // reflecteixi que no hi havia res a eliminar.
  async remove(userId, peakId) {
    const parsedPeakId = parsePositiveInteger(peakId);
    if (!parsedPeakId) {
      throw badRequest('Invalid peakId: must be a positive integer');
    }

    const affectedRows = await PeakStatusModel.deleteByUserAndPeak(userId, parsedPeakId);

    if (affectedRows === 0) {
      const error = new Error('Peak status not found');
      error.statusCode = 404;
      throw error;
    }
  },
};

module.exports = PeakStatusService;
