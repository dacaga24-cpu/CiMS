const AscentModel = require('../models/ascentModel');
const AscentPhotoModel = require('../models/ascentPhotoModel');
const PeakModel = require('../models/peakModel');
const AscentVerificationModel = require('../models/ascentVerificationModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const AscentVerificationService = require('./ascentVerificationService');
const pool = require('../config/db');

// Aquest servei manté coherent l'estat personal dels cims.
// Quan es registra una ascensió, el cim també queda marcat com a assolit.
const PeakStatusService = require('./peakStatusService');

// Aquest servei actualitza el repte mensual després de canvis en ascensions.
// Es crida com a efecte secundari perquè el progrés del dashboard continuï
// reflectint l'activitat real de l'usuari.
const MonthlyChallengeService = require('./monthlyChallengeService');

// Aquest helper executa accions derivades sense bloquejar l'operació principal.
// Si una sincronització falla, l'ascensió ja creada, editada o eliminada no es
// desfà, i l'error queda registrat als logs per poder revisar-lo.
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
  parseOptionalIsoDate,
} = require('../utils/validation');

// Defineix la longitud màxima de les notes d'una ascensió.
// Tot i que la base de dades permet textos més llargs, aquest límit manté
// les respostes controlades i evita usos excessius del camp.
const MAX_NOTES_LENGTH = 2000;

// Defineix el nombre màxim de fotos que pot tenir una mateixa ascensió.
// El frontend també treballa amb aquest límit, de manera que el comportament
// queda alineat entre client i servidor.
const MAX_PHOTOS_PER_ASCENT = 8;

// Aquesta funció valida les fotos rebudes en crear una ascensió.
// Només accepta imatges pujades dins l'espai del mateix usuari i impedeix
// superar el límit establert o marcar més d'una foto com a principal.
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
  let verificationEvidenceCount = 0;
  const normalized = [];

  for (const photo of photos) {
    if (!photo || typeof photo !== 'object') {
      throw badRequest('Invalid photos: each entry must be an object');
    }

    const { storagePath, isPrimary, isVerificationEvidence } = photo;

    if (typeof storagePath !== 'string' || !pathPattern.test(storagePath)) {
      throw badRequest('Invalid photos: storagePath has an unexpected shape or does not belong to the user namespace');
    }

    const isPrimaryBool = Boolean(isPrimary);
    const isVerificationEvidenceBool = Boolean(isVerificationEvidence);

    if (isPrimaryBool) {
      primaryCount += 1;
    }

    if (isVerificationEvidenceBool) {
      verificationEvidenceCount += 1;
    }

    normalized.push({
      storagePath,
      isPrimary: isPrimaryBool,
      isVerificationEvidence: isVerificationEvidenceBool,
    });
  }

  if (primaryCount > 1) {
    throw badRequest('Invalid photos: at most one photo can be marked as primary');
  }

  if (verificationEvidenceCount > 1) {
    throw badRequest('Invalid photos: at most one photo can be marked as verification evidence');
  }

  return normalized;
}

// Aquesta funció prepara les fotos d'una ascensió verificada.
// Garanteix que hi hagi una imatge principal marcada com a evidència de verificació.
function ensureVerificationPhotosPayload(userId, photos) {
  const normalized = ensureValidPhotosPayload(userId, photos);

  if (normalized.length === 0) {
    throw badRequest('Invalid photos: a verification photo is required');
  }

  const evidenceIndex = normalized.findIndex(
    (photo) => photo.isVerificationEvidence
  );

  const primaryIndex = normalized.findIndex((photo) => photo.isPrimary);
  const selectedIndex = evidenceIndex !== -1
    ? evidenceIndex
    : primaryIndex !== -1
      ? primaryIndex
      : 0;

  return normalized.map((photo, index) => ({
    ...photo,
    isPrimary: index === selectedIndex,
    isVerificationEvidence: index === selectedIndex,
  }));
}

// Aquesta funció comprova que les fotos declarades existeixen realment al bucket.
// Això evita guardar a la base de dades rutes d'imatges que no s'han arribat a pujar.
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

// Aquesta funció elimina del bucket les imatges associades a una ascensió.
// Si alguna imatge no es pot eliminar, l'ascensió no es restaura: l'error queda
// registrat i la neteja es podrà revisar posteriorment.
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

// Aquesta funció transforma les dades de verificació al format que espera el frontend.
// Permet mostrar l'estat d'una ascensió sense exposar els noms interns de la base de dades.
function attachVerificationToAscent(ascent) {
  ascent.verification = ascent.verification_id
    ? {
        id: ascent.verification_id,
        method: ascent.verification_method,
        status: ascent.verification_status,
        distanceToPeakMeters: ascent.verification_distance_to_peak_meters,
        checkedAt: ascent.verification_checked_at,
        reason: ascent.verification_reason,
      }
    : null;

  delete ascent.verification_id;
  delete ascent.verification_method;
  delete ascent.verification_status;
  delete ascent.verification_distance_to_peak_meters;
  delete ascent.verification_checked_at;
  delete ascent.verification_reason;

  return ascent;
}

// Aquesta funció adapta una verificació creada directament pel model.
// S'utilitza quan el servei acaba de crear una ascensió verificada i retorna la resposta.
function formatVerificationRow(verification) {
  if (!verification) {
    return null;
  }

  return {
    id: verification.id,
    method: verification.method,
    status: verification.status,
    distanceToPeakMeters: verification.distance_to_peak_meters,
    checkedAt: verification.checked_at,
    reason: verification.reason,
  };
}

// Aquesta funció afegeix a cada ascensió la seva foto principal i la seva verificació.
// S'utilitza en llistats perquè la interfície pugui mostrar una imatge resum
// i l'estat de validació sense carregar dades addicionals.
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

    attachVerificationToAscent(ascent);
  }

  return ascents;
}

// Aquesta funció valida les notes opcionals d'una ascensió.
// Permet deixar-les buides, però si s'envia text comprova que sigui vàlid
// i que no superi la longitud màxima acceptada.
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

// Aquest servei centralitza la gestió de les ascensions.
// Valida les dades rebudes, comprova la propietat de cada recurs i delega
// l'accés a base de dades als models corresponents.
const AscentService = {

  // Retorna totes les ascensions de l'usuari autenticat.
  // Cada ascensió inclou, si existeix, la seva foto principal amb URL temporal.
  async getByUser(userId) {
    const ascents = await AscentModel.findAllByUserId(userId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna les ascensions de l'usuari sobre un cim concret.
  // El resultat també inclou la foto principal de cada ascensió, si n'hi ha.
  async getByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const ascents = await AscentModel.findAllByUserAndPeak(userId, parsedPeakId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna totes les fotos d'una ascensió concreta.
  // Abans de consultar les imatges comprova que l'ascensió pertanyi a l'usuari.
  async getPhotosForAscent(userId, ascentId) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    const photos = await AscentPhotoModel.findAllByAscentIdAndUserId(
      parsedAscentId,
      userId
    );

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
          isVerificationEvidence: photo.is_verification_evidence === 1,
          downloadUrl,
          createdAt: photo.created_at,
        };
      })
    );
  },

  // Crea una nova ascensió per a l'usuari autenticat.
  // També pot associar-hi fotos ja pujades al bucket i marca el cim com a assolit.
  async create(userId, { peakId, ascentDate, notes, photos } = {}) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const parsedDate = parseOptionalIsoDate(ascentDate, 'ascentDate') ?? null;
    const validatedNotes = ensureValidNotes(notes);
    const validatedPhotos = ensureValidPhotosPayload(userId, photos);

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
      try {
        await connection.rollback();
      } catch (rollbackErr) {
        console.error('[ascents] rollback failed after transaction error:', rollbackErr);
      }

      throw err;
    } finally {
      connection.release();
    }

    await safeSideEffect(
      'peakStatus.upsert',
      PeakStatusService.upsertPeakStatus(userId, parsedPeakId, {
        isCompleted: true,
      })
    );

    if (parsedDate !== null) {
      await safeSideEffect(
        'monthlyChallenge.recompute',
        MonthlyChallengeService.recomputeForUser(userId, parsedDate)
      );
    }

    return {
      ...attachVerificationToAscent(createdAscent),
      photos: createdPhotos,
    };
  },

  // Crea una ascensió verificada amb la ubicació capturada pel dispositiu.
  // La data queda bloquejada perquè prové del moment real de captura de l'evidència.
  async createVerifiedFromDeviceLocation(
    userId,
    {
      peakId,
      notes,
      photos,
      capturedLatitude,
      capturedLongitude,
      capturedAccuracyMeters,
      capturedAt,
    } = {}
  ) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const validatedNotes = ensureValidNotes(notes);
    const validatedPhotos = ensureVerificationPhotosPayload(userId, photos);

    await ensurePhotosExistInBucket(validatedPhotos);

    const peak = await PeakModel.findById(parsedPeakId);

    const verification = AscentVerificationService.evaluateVerification({
      method: 'device_location',
      peak,
      capturedLatitude,
      capturedLongitude,
      capturedAccuracyMeters,
      capturedAt,
    });

    if (verification.status === 'rejected') {
      throw badRequest(`Verification rejected: ${verification.reason}`);
    }

    const ascentDate = verification.capturedAt.toISOString().slice(0, 10);

    const connection = await pool.getConnection();
    let createdAscent;
    let createdPhotos = [];
    let createdVerification;

    try {
      await connection.beginTransaction();

      createdAscent = await AscentModel.create({
        userId,
        peakId: parsedPeakId,
        ascentDate,
        notes: validatedNotes ?? null,
        isDateLocked: 1,
      }, connection);

      createdPhotos = await AscentPhotoModel.createMany(
        createdAscent.id,
        validatedPhotos,
        connection
      );

      createdVerification = await AscentVerificationModel.create({
        ascentId: createdAscent.id,
        method: verification.method,
        status: verification.status,
        capturedLatitude: verification.capturedLatitude,
        capturedLongitude: verification.capturedLongitude,
        capturedAccuracyMeters: verification.capturedAccuracyMeters,
        capturedAt: verification.capturedAt,
        distanceToPeakMeters: verification.distanceToPeakMeters,
        checkedAt: verification.checkedAt,
        reason: verification.reason,
      }, connection);

      await connection.commit();
    } catch (err) {
      try {
        await connection.rollback();
      } catch (rollbackErr) {
        console.error('[ascents] rollback failed after verified transaction error:', rollbackErr);
      }

      throw err;
    } finally {
      connection.release();
    }

    if (verification.status === 'verified') {
      await safeSideEffect(
        'peakStatus.upsert',
        PeakStatusService.upsertPeakStatus(userId, parsedPeakId, {
          isCompleted: true,
        })
      );

      await safeSideEffect(
        'monthlyChallenge.recompute',
        MonthlyChallengeService.recomputeForUser(userId, ascentDate)
      );
    }

    return {
      ...attachVerificationToAscent(createdAscent),
      photos: createdPhotos,
      verification: formatVerificationRow(createdVerification),
    };
  },

  // Actualitza una ascensió existent de l'usuari autenticat.
  // Només modifica els camps enviats i manté ocult si l'ascensió no existeix
  // o pertany a un altre usuari.
  async update(userId, ascentId, { peakId, ascentDate, notes } = {}) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    const payload = {};

    if (peakId !== undefined) {
      payload.peakId = requireInteger(peakId, 'peakId');
    }

    if (ascentDate !== undefined) {
      payload.ascentDate = parseOptionalIsoDate(ascentDate, 'ascentDate') ?? null;
    }

    if (notes !== undefined) {
      payload.notes = ensureValidNotes(notes);
    }

    if (Object.keys(payload).length > 0) {
      await AscentModel.updateByIdAndUserId(userId, parsedAscentId, payload);
    }

    if (payload.peakId !== undefined) {
      await safeSideEffect(
        'peakStatus.upsert',
        PeakStatusService.upsertPeakStatus(userId, payload.peakId, {
          isCompleted: true,
        })
      );

      const remainingAscentsOnPreviousPeak = await AscentModel.countByUserAndPeak(
        userId,
        existing.peak_id
      );

      if (remainingAscentsOnPreviousPeak === 0) {
        await safeSideEffect(
          'peakStatus.uncompletePreviousPeak',
          PeakStatusService.upsertPeakStatus(userId, existing.peak_id, {
            isCompleted: false,
          })
        );
      }
    }

    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeCurrentMonthForUser(userId)
    );

    const updated = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    return attachVerificationToAscent(updated);
  },

  // Elimina una ascensió de l'usuari autenticat.
  // També intenta eliminar les fotos del bucket i actualitza el repte mensual.
  async remove(userId, ascentId) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    const photos = await AscentPhotoModel.findAllByAscentIdAndUserId(
      parsedAscentId,
      userId
    );

    await AscentModel.deleteByIdAndUserId(userId, parsedAscentId);

    await safeDeletePhotoBlobs(
      photos.map((photo) => photo.storage_path),
      {
        userId,
        ascentId: parsedAscentId,
      }
    );

    const remainingAscents = await AscentModel.countByUserAndPeak(
      userId,
      existing.peak_id
    );

    if (remainingAscents === 0) {
      await safeSideEffect(
        'peakStatus.uncomplete',
        PeakStatusService.upsertPeakStatus(userId, existing.peak_id, {
          isCompleted: false,
        })
      );
    }

    await safeSideEffect(
      'monthlyChallenge.recompute',
      MonthlyChallengeService.recomputeCurrentMonthForUser(userId)
    );
  },
};

module.exports = AscentService;