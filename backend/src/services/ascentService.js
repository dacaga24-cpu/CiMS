const AscentModel = require('../models/ascentModel');
const {
  badRequest,
  requireInteger,
  requireIsoDate,
  parseOptionalIsoDate,
} = require('../utils/validation');

// Límit de longitud de les notes d'una ascensió. La columna a la base de
// dades és TEXT (fins a 65535 caràcters), però aquest límit més estricte
// protegeix l'API d'usos abusius i manté la mida de les respostes raonable.
const MAX_NOTES_LENGTH = 2000;

// Aquest mètode valida el camp opcional notes. Si s'ha enviat ha de ser una
// cadena dins del límit acceptat, però es permet enviar null o cadena buida
// per netejar les notes existents.
function ensureValidNotes(value) {
  if (value === undefined || value === null) {
    return value;
  }
  if (typeof value !== 'string') {
    throw badRequest('Invalid notes: must be a string');
  }
  if (value.length > MAX_NOTES_LENGTH) {
    throw badRequest(`Invalid notes: must be at most ${MAX_NOTES_LENGTH} characters`);
  }
  return value;
}

// Aquest servei centralitza la lògica de les ascensions. Aquí es valida el
// payload, s'aplica la coerció dels camps i es delega a la capa de model
// l'accés real a la base de dades. La capa de servei és l'única responsable
// de comprovar que els recursos sol·licitats pertanyen a l'usuari autenticat.
const AscentService = {

  // Retorna totes les ascensions de l'usuari autenticat.
  // Una llista buida és un resultat vàlid (200) per a un usuari nou.
  async getByUser(userId) {
    return AscentModel.findAllByUserId(userId);
  },

  // Retorna les ascensions de l'usuari autenticat sobre un cim concret.
  // El peakId es valida com a enter positiu. No es comprova prèviament que el
  // cim existeixi: si no hi ha cap ascensió, simplement retorna llista buida.
  async getByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    return AscentModel.findAllByUserAndPeak(userId, parsedPeakId);
  },

  // Crea una nova ascensió per a l'usuari autenticat. peakId i ascentDate són
  // obligatoris; notes és opcional. La validació de l'existència del cim la
  // fa la foreign key al model, que torna un 404 clar si el cim no existeix.
  async create(userId, { peakId, ascentDate, notes } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const parsedDate = requireIsoDate(ascentDate, 'ascentDate');
    const validatedNotes = ensureValidNotes(notes);

    return AscentModel.create({
      userId,
      peakId: parsedPeakId,
      ascentDate: parsedDate,
      notes: validatedNotes ?? null,
    });
  },

  // Actualitza els camps indicats d'una ascensió existent. Cal que l'ascensió
  // pertanyi a l'usuari autenticat: si no existeix o és d'un altre usuari, es
  // respon 404 sense distingir els dos casos per no filtrar informació.
  // Es valida primer que existeixi i després s'apliquen les actualitzacions
  // perquè el missatge d'error d'una ascensió inexistent sempre sigui el mateix
  // independentment del format dels camps enviats.
  async update(userId, ascentId, { peakId, ascentDate, notes } = {}) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    // Cada camp s'analitza només si el client l'ha enviat. Això permet
    // actualitzacions parcials (per exemple, només les notes) sense haver
    // de reenviar la resta de l'ascensió.
    const payload = {};

    if (peakId !== undefined) {
      payload.peakId = requireInteger(peakId, 'peakId');
    }

    if (ascentDate !== undefined) {
      payload.ascentDate = parseOptionalIsoDate(ascentDate, 'ascentDate');
    }

    if (notes !== undefined) {
      payload.notes = ensureValidNotes(notes);
    }

    // Si el cos de la petició ha arribat sense cap camp modificable es retorna
    // l'ascensió tal com està, perquè un PUT sense canvis no és un error sinó
    // una idempotència trivial.
    if (Object.keys(payload).length > 0) {
      await AscentModel.updateByIdAndUserId(userId, parsedAscentId, payload);
    }

    return AscentModel.findByIdAndUserId(userId, parsedAscentId);
  },

  // Elimina una ascensió de l'usuari autenticat. Si no existeix o és d'un
  // altre usuari, es respon 404 (mateix criteri que update).
  async remove(userId, ascentId) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const affectedRows = await AscentModel.deleteByIdAndUserId(userId, parsedAscentId);
    if (affectedRows === 0) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }
  },
};

module.exports = AscentService;
