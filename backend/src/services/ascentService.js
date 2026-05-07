const AscentModel = require('../models/ascentModel');
const AscentPhotoModel = require('../models/ascentPhotoModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const pool = require('../config/db');

// Sincronitza l'estat personal del cim quan l'usuari registra una ascensió.
const PeakStatusService = require('./peakStatusService');

// Recalcula el progrés del repte mensual des de la taula ascents per mantenir
// sincronitzat el cache (monthly_challenge_progress). Es crida dins
// safeSideEffect perquè un error al cache no enderroqui l'operació principal.
const MonthlyChallengeService = require('./monthlyChallengeService');

// Envolta els efectes derivats després de confirmar un ascens (peak_status,
// repte mensual). Si en propaguéssim els errors l'usuari rebria un 500 després
// del commit i podria reintentar creant un duplicat.
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

// Límit més estricte que la columna TEXT de la BD per acotar la mida de la
// resposta i evitar usos abusius.
const MAX_NOTES_LENGTH = 2000;

// Sostre total de fotos per ascensió per acotar la resposta i el cost del bucket.
const MAX_PHOTOS_PER_ASCENT = 11;

// Valida l'array opcional de fotos del payload de creació. El patró estricte
// (UUID v4 + extensió whitelist + namespace de l'usuari) tanca path traversal
// i evita que un client reclami fotos pujades per altres usuaris.
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

// Verifica en paral·lel que els blobs declarats pel client existeixen al
// bucket. Sense això, un client podria registrar paths inexistents i deixar
// files orfes a ascent_photos.
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

// Esborra blobs sense aturar el flux si algun esborrat falla. ON DELETE
// CASCADE neteja la BD però els blobs s'han d'esborrar explícitament del
// bucket; un blob no esborrable es recuperarà amb un job d'orfes posterior.
// El log inclou userId+ascentId per correlacionar amb l'ascens eliminat.
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

// Enriqueix una llista d'ascens amb la primaryPhoto signada. Una sola query
// agrupada evita N+1 i les signatures es generen en paral·lel. Només es
// retorna la principal per no inflar el llistat amb signatures de totes les
// fotos. Una signatura fallida degrada a downloadUrl null perquè el llistat
// no caigui per una foto puntual.
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

// Valida el camp opcional notes. null o cadena buida són vàlids per netejar
// les notes existents.
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

// Lògica de les ascensions: valida el payload, coerciona els camps i delega
// al model. Garanteix que els recursos pertanyen a l'usuari autenticat.
const AscentService = {

  // Llista les ascensions de l'usuari amb la primaryPhoto signada.
  async getByUser(userId) {
    const ascents = await AscentModel.findAllByUserId(userId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Llista les ascensions de l'usuari sobre un cim concret amb la primaryPhoto
  // signada. peakId es valida; si no hi ha cap ascensió, retorna llista buida.
  async getByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const ascents = await AscentModel.findAllByUserAndPeak(userId, parsedPeakId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna totes les fotos d'un ascens amb signed URL. L'ownership es valida
  // amb findByIdAndUserId primer per respondre 404 abans de tocar el bucket.
  // Si una signatura falla, aquella foto es retorna amb downloadUrl null.
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

  // Crea una ascensió. peakId i ascentDate són obligatoris; notes i photos
  // opcionals. L'ascens i les fotos s'insereixen en una sola transacció: si
  // una foto falla, rollback i no queda mig-ascens a la BD. Els blobs ja
  // pujats queden com a orfes per a un job de neteja posterior.
  async create(userId, { peakId, ascentDate, notes, photos } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const parsedDate = requireIsoDate(ascentDate, 'ascentDate');
    const validatedNotes = ensureValidNotes(notes);
    const validatedPhotos = ensureValidPhotosPayload(userId, photos);

    // Comprovar blobs abans d'obrir transacció: així no bloquegem cap
    // connection mentre s'esperen els HEAD a GCS.
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
      // Rollback dins de try/catch perquè un error al rollback no emmascari
      // l'error original.
      try {
        await connection.rollback();
      } catch (rollbackErr) {
        console.error('[ascents] rollback failed after transaction error:', rollbackErr);
      }
      throw err;
    } finally {
      connection.release();
    }

    // Marcar el cim com a assolit. Efecte derivat: si peta després del commit,
    // l'ascens ja existeix i no volem que el client rebi un 500 i reintenti.
    await safeSideEffect(
      'peakStatus.upsert',
      PeakStatusService.upsertPeakStatus(userId, parsedPeakId, {
        isCompleted: true,
      })
    );

    // Si la nova ascensió cau al mes en curs, pot fer pujar el repte mensual.
    // El servei filtra per data internament.
    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeForUser(userId, parsedDate)
    );

    return { ...createdAscent, photos: createdPhotos };
  },

  // Actualitza camps d'una ascensió. 404 si no existeix o és d'un altre
  // usuari, sense distingir per no filtrar informació.
  async update(userId, ascentId, { peakId, ascentDate, notes } = {}) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    // Cada camp s'analitza només si el client l'ha enviat: permet
    // actualitzacions parcials.
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

    // PUT sense canvis: idempotència trivial, no és error.
    if (Object.keys(payload).length > 0) {
      await AscentModel.updateByIdAndUserId(userId, parsedAscentId, payload);
    }

    // Si es reassigna a un altre cim, marcar-lo com a assolit. Efecte derivat.
    if (payload.peakId !== undefined) {
      await safeSideEffect(
        'peakStatus.upsert',
        PeakStatusService.upsertPeakStatus(userId, payload.peakId, {
          isCompleted: true,
        })
      );
    }

    // Una edició pot canviar la data o el cim, així que es recalcula sempre
    // el mes en curs.
    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeCurrentMonthForUser(userId)
    );

    return AscentModel.findByIdAndUserId(userId, parsedAscentId);
  },

  // Elimina una ascensió. 404 si no existeix o és d'un altre usuari. Es
  // recuperen els paths abans del DELETE i s'esborren els blobs després,
  // perquè ON DELETE CASCADE viu només a la BD i no toca el bucket.
  async remove(userId, ascentId) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const photos = await AscentPhotoModel.findAllByAscentIdAndUserId(parsedAscentId, userId);

    const affectedRows = await AscentModel.deleteByIdAndUserId(userId, parsedAscentId);
    if (affectedRows === 0) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    // Carrera amb un altre delete concurrent: ignoreNotFound al StorageService
    // fa segur el doble esborrat.
    await safeDeletePhotoBlobs(
      photos.map((photo) => photo.storage_path),
      { userId, ascentId: parsedAscentId }
    );

    // Pot fer baixar el repte mensual si l'ascensió era del mes en curs.
    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeCurrentMonthForUser(userId)
    );
  },
};

module.exports = AscentService;
