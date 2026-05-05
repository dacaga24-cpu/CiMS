const AscentModel = require('../models/ascentModel');

// Aquest servei permet mantenir sincronitzat l'estat personal del cim.
// Quan un usuari registra una ascensió, el cim també ha de quedar marcat
// com a assolit dins del seu estat personal.
const PeakStatusService = require('./peakStatusService');

// Cada modificació d'ascensions pot afectar el progrés del repte mensual
// de l'usuari. El servei recalcula el progrés a partir de la taula ascents,
// així que invocar-lo després de qualsevol create/update/remove garanteix
// que el cache (monthly_challenge_progress) sempre reflecteixi la realitat.
// Les crides es fan dins de safeRecompute per evitar que un error al cache
// faci fracassar l'operació principal d'ascents, que ja s'ha confirmat.
const MonthlyChallengeService = require('./monthlyChallengeService');

// El recompute del repte mensual és un efecte derivat: si peta no s'ha de
// propagar a la resposta de l'endpoint d'ascents, perquè la dada principal
// (l'ascensió) ja està persistida i la pròxima crida tornarà a recalcular
// el cache des de zero. Es loguen els errors perquè es puguin diagnosticar
// sense bloquejar el flux de l'usuari.
async function safeRecompute(promise) {
  try {
    await promise;
  } catch (err) {
    console.error('[monthlyChallenge] recompute failed:', err);
  }
}

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

    const ascent = await AscentModel.create({
      userId,
      peakId: parsedPeakId,
      ascentDate: parsedDate,
      notes: validatedNotes ?? null,
    });

    // Registrar una ascensió implica que l'usuari ha assolit aquell cim.
    // Per això, després de guardar l'ascensió, també s'actualitza el seu
    // estat personal perquè el cim aparegui com a completat.
    await PeakStatusService.upsertPeakStatus(userId, parsedPeakId, {
      isCompleted: true,
    });

    // Si la nova ascensió pertany al mes en curs, pot fer pujar el progrés
    // del repte mensual de l'usuari. El servei filtra internament per data,
    // així que enviar-li sempre la ascentDate és segur.
    await safeRecompute(MonthlyChallengeService.recomputeForUser(userId, parsedDate));

    return ascent;
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

    // Si una ascensió es reassigna a un altre cim, el nou cim també ha de
    // quedar marcat com a assolit per mantenir coherent l'historial de
    // l'usuari amb l'estat personal dels seus cims.
    if (payload.peakId !== undefined) {
      await PeakStatusService.upsertPeakStatus(userId, payload.peakId, {
        isCompleted: true,
      });
    }

    // Una edició pot canviar la data o el cim de l'ascensió, i tant la data
    // antiga com la nova podrien caure dins del mes en curs. És més segur
    // demanar un recompute del mes actual sencer que comprovar dues dates
    // per separat: el cost és una sola query agregada sobre ascents.
    await safeRecompute(MonthlyChallengeService.recomputeCurrentMonthForUser(userId));

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

    // L'eliminació pot fer baixar el progrés del repte mensual si l'ascensió
    // esborrada era del mes en curs. Es recalcula sempre perquè aquí ja no
    // tenim accés a la data original, i el cost és el mateix recompute
    // agregat que ja s'usa des d'update.
    await safeRecompute(MonthlyChallengeService.recomputeCurrentMonthForUser(userId));
  },
};

module.exports = AscentService;
