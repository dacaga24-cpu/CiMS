const AscentModel = require('../models/ascentModel');
const AscentPhotoModel = require('../models/ascentPhotoModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const pool = require('../config/db');

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

// Els efectes derivats que disparem després de confirmar un ascens
// (sincronitzar peak_status, recalcular el repte mensual) no s'han de
// propagar com a errors a l'endpoint d'ascents: la dada principal ja està
// persistida i, si l'usuari rebés un 500, podria reintentar i crear un
// duplicat. Per això s'envolten en aquest helper, que loga el problema
// sense bloquejar el flux. Es passa un label per identificar quin efecte
// ha fallat als logs i facilitar la diagnosi.
async function safeSideEffect(label, promise) {
  try {
    await promise;
  } catch (err) {
    console.error(`[ascents] side effect failed (${label}):`, err);
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

// Sostre total de fotos per ascensió. La validació no obliga que cap sigui
// principal, però com a màxim una pot estar marcada com a tal. El límit
// serveix per acotar la mida de les respostes i el cost del bucket.
const MAX_PHOTOS_PER_ASCENT = 11;

// Aquest mètode valida l'array opcional de fotos del payload de creació
// d'ascens. Comprova que sigui un array, que no superi el sostre, que com
// a màxim una sigui marcada com a principal i que cada storagePath
// segueixi exactament el patró que produeix el StorageService per a aquest
// usuari concret. El patró estricte (UUID v4 + extensió de la whitelist)
// tanca la porta a path traversal i evita que un client pugui reclamar
// fotos pujades per altres usuaris.
function ensureValidPhotosPayload(userId, photos) {
  if (photos === undefined || photos === null) {
    return [];
  }
  if (!Array.isArray(photos)) {
    throw badRequest('Invalid photos: must be an array');
  }
  if (photos.length > MAX_PHOTOS_PER_ASCENT) {
    throw badRequest(`Invalid photos: at most ${MAX_PHOTOS_PER_ASCENT} per ascent`);
  }

  const pathPattern = buildUserPathPattern(userId, 'ascents');
  let primaryCount = 0;
  const normalized = [];

  for (const photo of photos) {
    if (!photo || typeof photo !== 'object') {
      throw badRequest('Invalid photos: each entry must be an object');
    }
    const { storagePath, isPrimary } = photo;
    if (typeof storagePath !== 'string' || !pathPattern.test(storagePath)) {
      throw badRequest('Invalid photos: storagePath has an unexpected shape or does not belong to the user namespace');
    }
    const isPrimaryBool = Boolean(isPrimary);
    if (isPrimaryBool) {
      primaryCount += 1;
    }
    normalized.push({ storagePath, isPrimary: isPrimaryBool });
  }

  if (primaryCount > 1) {
    throw badRequest('Invalid photos: at most one photo can be marked as primary');
  }

  return normalized;
}

// Aquest mètode comprova que tots els blobs declarats pel client existeixen
// realment al bucket. Sense aquesta validació, un client podria registrar
// paths inexistents i deixar files orfes a ascent_photos. Les comprovacions
// es fan en paral·lel per minimitzar la latència total.
async function ensurePhotosExistInBucket(photos) {
  if (photos.length === 0) {
    return;
  }
  const checks = await Promise.all(
    photos.map((photo) => StorageService.objectExists(photo.storagePath))
  );
  const missingIndex = checks.findIndex((exists) => !exists);
  if (missingIndex !== -1) {
    throw badRequest(
      `Invalid photos: storagePath does not exist in storage (${photos[missingIndex].storagePath})`
    );
  }
}

// Aquest helper esborra una llista de blobs del bucket sense aturar el flux
// si algun esborrat falla. S'usa quan s'elimina un ascens: ON DELETE CASCADE
// neteja les files de la BD, però els blobs s'han d'esborrar explícitament
// del bucket. Que un blob no es pugui esborrar (per exemple per un error
// transitori de GCS) no ha de bloquejar l'eliminació, ja es podran netejar
// orfes amb un job posterior.
//
// El context (userId, ascentId) s'inclou al log perquè el responsable de
// la neteja d'orfes pugui correlacionar el path al bucket amb l'ascens
// eliminat sense haver de creuar logs amb consultes a la BD.
async function safeDeletePhotoBlobs(storagePaths, context = {}) {
  if (storagePaths.length === 0) {
    return;
  }
  await Promise.all(
    storagePaths.map(async (path) => {
      try {
        await StorageService.deleteObject(path);
      } catch (err) {
        console.error(
          `[ascentPhotos] orphan blob (userId=${context.userId ?? 'unknown'} ascentId=${context.ascentId ?? 'unknown'} path=${path}):`,
          err
        );
      }
    })
  );
}

// Aquest helper enriqueix una llista d'ascens amb el camp primaryPhoto
// (la foto principal amb signed download URL ja generada) o null si
// l'ascens no en té. Es fa una sola query per recuperar totes les
// principals dels ascens donats (evita N+1) i les signed URLs es generen
// en paral·lel per minimitzar la latència total. Es retorna només la
// principal i no totes les fotos perquè els llistats poden tenir desenes
// d'ascens i emetre signed URLs per a totes les memòries inflaria
// innecessàriament la resposta i el cost de signing.
//
// Si una signatura concreta falla (problema transitori de GCS), es
// degrada aquella foto a downloadUrl null i es loga l'error: el llistat
// d'ascens és navegació primària de l'app i no ha de caure perquè una
// foto no es pugui mostrar puntualment.
async function attachPrimaryPhotoToAscents(ascents) {
  if (ascents.length === 0) {
    return ascents;
  }

  const ascentIds = ascents.map((ascent) => ascent.id);
  const primariesById = await AscentPhotoModel.findPrimaryByAscentIds(ascentIds);

  const photosToSign = [...primariesById.values()];
  const signedUrlByPath = new Map();
  await Promise.all(
    photosToSign.map(async (photo) => {
      try {
        const url = await StorageService.generateSignedDownloadUrl(photo.storage_path);
        signedUrlByPath.set(photo.storage_path, url);
      } catch (err) {
        console.error(
          `[ascentPhotos] sign download URL failed (ascentId=${photo.ascent_id} path=${photo.storage_path}):`,
          err
        );
        signedUrlByPath.set(photo.storage_path, null);
      }
    })
  );

  for (const ascent of ascents) {
    const primary = primariesById.get(ascent.id);
    ascent.primaryPhoto = primary
      ? {
          id: primary.id,
          storagePath: primary.storage_path,
          downloadUrl: signedUrlByPath.get(primary.storage_path),
        }
      : null;
  }

  return ascents;
}

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

  // Retorna totes les ascensions de l'usuari autenticat amb la seva foto
  // principal enriquida amb signed URL de descàrrega. Una llista buida és
  // un resultat vàlid (200) per a un usuari nou.
  async getByUser(userId) {
    const ascents = await AscentModel.findAllByUserId(userId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna les ascensions de l'usuari autenticat sobre un cim concret amb
  // la seva foto principal enriquida amb signed URL de descàrrega. El peakId
  // es valida com a enter positiu. No es comprova prèviament que el cim
  // existeixi: si no hi ha cap ascensió, simplement retorna llista buida.
  async getByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const ascents = await AscentModel.findAllByUserAndPeak(userId, parsedPeakId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna totes les fotos d'un ascens concret amb signed URL de
  // descàrrega per a cadascuna. La validació d'ownership es fa primer amb
  // findByIdAndUserId perquè el cas "ascens d'un altre usuari" respongui
  // 404 abans de fer cap query addicional ni consultar el bucket. Si
  // l'usuari té l'ascens però sense fotos, retorna una llista buida.
  //
  // Si la signatura d'una URL concreta falla per un problema transitori
  // de GCS, aquella foto es retorna amb downloadUrl null i es loga
  // l'error: la pantalla de detall ha de poder mostrar-se encara que
  // alguna foto no es pugui carregar puntualment.
  async getPhotosForAscent(userId, ascentId) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    const photos = await AscentPhotoModel.findAllByAscentIdAndUserId(parsedAscentId, userId);

    return Promise.all(
      photos.map(async (photo) => {
        let downloadUrl = null;
        try {
          downloadUrl = await StorageService.generateSignedDownloadUrl(photo.storage_path);
        } catch (err) {
          console.error(
            `[ascentPhotos] sign download URL failed (ascentId=${photo.ascent_id} path=${photo.storage_path}):`,
            err
          );
        }
        return {
          id: photo.id,
          ascentId: photo.ascent_id,
          storagePath: photo.storage_path,
          isPrimary: photo.is_primary === 1,
          downloadUrl,
          createdAt: photo.created_at,
        };
      })
    );
  },

  // Crea una nova ascensió per a l'usuari autenticat. peakId i ascentDate són
  // obligatoris; notes i photos són opcionals. La validació de l'existència
  // del cim la fa la foreign key al model, que torna un 404 clar si el cim
  // no existeix.
  //
  // Si arriba l'array photos, cada entrada ha de portar un storagePath que
  // ja apunta a un blob pujat al bucket via signed URL. La inserció de
  // l'ascens i les seves fotos es fa en una sola transacció: si la inserció
  // de qualsevol foto falla després de crear l'ascens, es fa rollback i el
  // client rep l'error sense que quedi mig-ascens a la BD. Els blobs ja
  // pujats no s'esborren automàticament (queden com a orfes que es
  // netejaran amb una política de cicle de vida del bucket o un job futur).
  async create(userId, { peakId, ascentDate, notes, photos } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const parsedDate = requireIsoDate(ascentDate, 'ascentDate');
    const validatedNotes = ensureValidNotes(notes);
    const validatedPhotos = ensureValidPhotosPayload(userId, photos);

    // El check d'existència dels blobs es fa abans d'obrir la transacció
    // per no mantenir cap connection bloquejada mentre s'esperen les
    // peticions HEAD a GCS. Si algun blob falta, es respon 400 sense haver
    // tocat la base de dades.
    await ensurePhotosExistInBucket(validatedPhotos);

    const connection = await pool.getConnection();
    let createdAscent;
    let createdPhotos = [];
    try {
      await connection.beginTransaction();
      createdAscent = await AscentModel.create({
        userId,
        peakId: parsedPeakId,
        ascentDate: parsedDate,
        notes: validatedNotes ?? null,
      }, connection);

      if (validatedPhotos.length > 0) {
        createdPhotos = await AscentPhotoModel.createMany(
          createdAscent.id,
          validatedPhotos,
          connection
        );
      }
      await connection.commit();
    } catch (err) {
      // El rollback es fa dins del seu propi try/catch perquè un error al
      // rollback (per exemple, connexió ja morta) no emmascari l'error
      // original que ha provocat l'avortament de la transacció.
      try {
        await connection.rollback();
      } catch (rollbackErr) {
        console.error('[ascents] rollback failed after transaction error:', rollbackErr);
      }
      throw err;
    } finally {
      connection.release();
    }

    // Registrar una ascensió implica que l'usuari ha assolit aquell cim.
    // L'actualització de peak_status és un efecte derivat: si peta després
    // del commit, l'ascens ja existeix i no volem que el client rebi un 500
    // que el faria reintentar i crear un duplicat.
    await safeSideEffect(
      'peakStatus.upsert',
      PeakStatusService.upsertPeakStatus(userId, parsedPeakId, {
        isCompleted: true,
      })
    );

    // Si la nova ascensió pertany al mes en curs, pot fer pujar el progrés
    // del repte mensual de l'usuari. El servei filtra internament per data,
    // així que enviar-li sempre la ascentDate és segur.
    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeForUser(userId, parsedDate)
    );

    return { ...createdAscent, photos: createdPhotos };
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
    // l'usuari amb l'estat personal dels seus cims. És efecte derivat: si
    // peta no s'ha de propagar, perquè l'ascens ja s'ha actualitzat.
    if (payload.peakId !== undefined) {
      await safeSideEffect(
        'peakStatus.upsert',
        PeakStatusService.upsertPeakStatus(userId, payload.peakId, {
          isCompleted: true,
        })
      );
    }

    // Una edició pot canviar la data o el cim de l'ascensió, i tant la data
    // antiga com la nova podrien caure dins del mes en curs. És més segur
    // demanar un recompute del mes actual sencer que comprovar dues dates
    // per separat: el cost és una sola query agregada sobre ascents.
    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeCurrentMonthForUser(userId)
    );

    return AscentModel.findByIdAndUserId(userId, parsedAscentId);
  },

  // Elimina una ascensió de l'usuari autenticat. Si no existeix o és d'un
  // altre usuari, es respon 404 (mateix criteri que update).
  //
  // Abans d'esborrar la fila d'ascents, es recuperen els paths de les fotos
  // associades (filtrant per ownership a la mateixa query, no només pel
  // findByIdAndUserId previ) i s'esborren els blobs corresponents del
  // bucket. Les files d'ascent_photos s'esborren soles via ON DELETE
  // CASCADE; els blobs no, perquè CASCADE només viu a la BD. L'esborrat
  // dels blobs es fa amb safeDeletePhotoBlobs perquè un fallo de GCS no
  // bloquegi l'eliminació de l'ascens.
  async remove(userId, ascentId) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const photos = await AscentPhotoModel.findAllByAscentIdAndUserId(parsedAscentId, userId);

    const affectedRows = await AscentModel.deleteByIdAndUserId(userId, parsedAscentId);
    if (affectedRows === 0) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    // En cas de carrera amb un altre delete concurrent, els dos processos
    // poden intentar esborrar els mateixos blobs. ignoreNotFound al
    // StorageService fa que el segon esborrat no llanci, així que és
    // segur tornar a esborrar.
    await safeDeletePhotoBlobs(
      photos.map((photo) => photo.storage_path),
      { userId, ascentId: parsedAscentId }
    );

    // L'eliminació pot fer baixar el progrés del repte mensual si l'ascensió
    // esborrada era del mes en curs. Es recalcula sempre perquè aquí ja no
    // tenim accés a la data original, i el cost és el mateix recompute
    // agregat que ja s'usa des d'update.
    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeCurrentMonthForUser(userId)
    );
  },
};

module.exports = AscentService;
