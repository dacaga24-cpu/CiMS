const AscentModel = require('../models/ascentModel');
const AscentPhotoModel = require('../models/ascentPhotoModel');
const PeakModel = require('../models/peakModel');
const AscentVerificationModel = require('../models/ascentVerificationModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const AscentVerificationService = require('./ascentVerificationService');
const pool = require('../config/db');

// Aquest servei manté coherent l’estat personal dels cims.
// Quan es registra una ascensió, el cim també queda marcat com a assolit.
const PeakStatusService = require('./peakStatusService');

// Aquest servei actualitza el repte mensual quan canvien les ascensions.
// Això permet que el dashboard reflecteixi el progrés real de l’usuari.
const MonthlyChallengeService = require('./monthlyChallengeService');

// Aquest helper executa accions secundàries sense bloquejar l’operació principal.
// Si una sincronització falla, l’error queda registrat però no es desfà l’ascensió.
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

// Defineix la longitud màxima de les notes d’una ascensió.
// Manté el contingut controlat i evita textos excessivament grans.
const MAX_NOTES_LENGTH = 2000;

// Defineix el nombre màxim de fotos per ascensió.
// Manté el mateix límit funcional entre frontend i backend.
const MAX_PHOTOS_PER_ASCENT = 8;

// Aquesta funció valida les fotos rebudes en una ascensió.
// Comprova que pertanyin a l’usuari i que respectin els límits establerts.
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

// Aquesta funció prepara les fotos d’una ascensió verificada.
// Garanteix que hi hagi una imatge principal marcada com a evidència.
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

// Aquesta funció prepara les fotos afegides des de l’edició d’una ascensió.
// Les noves fotos no poden convertir-se en evidència de verificació.
function normalizeAdditionalPhotosPayload(existingPhotos, photos) {
  if (photos.length === 0) {
    throw badRequest('Invalid photos: at least one photo is required');
  }

  const hasExistingPrimary = existingPhotos.some(
    (photo) => photo.is_primary === 1
  );

  const hasExistingPhotos = existingPhotos.length > 0;

  return photos.map((photo, index) => {
    if (photo.isVerificationEvidence) {
      throw badRequest('Invalid photos: verification evidence cannot be added from ascent editing');
    }

    return {
      ...photo,
      isPrimary: hasExistingPhotos || hasExistingPrimary
        ? false
        : index === 0,
      isVerificationEvidence: false,
    };
  });
}

// Aquesta funció comprova que les fotos declarades existeixin al bucket.
// Evita guardar referències a imatges que no s’han pujat realment.
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

// Aquesta funció intenta eliminar del bucket les imatges d’una ascensió.
// Si alguna eliminació falla, l’error queda registrat per revisar possibles fitxers orfes.
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

// Aquesta funció adapta la verificació d’una ascensió al format del frontend.
// Permet mostrar l’estat de validació sense exposar noms interns de la base de dades.
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

// Aquesta funció adapta una verificació acabada de crear.
// S’utilitza per retornar la resposta d’una ascensió verificada amb el format esperat.
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

// Aquesta funció afegeix a cada ascensió la seva foto principal i la verificació.
// Permet mostrar llistats amb imatge resum i estat de validació.
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
          ascentId: primary.ascent_id,
          storagePath: primary.storage_path,
          isPrimary: primary.is_primary === 1,
          isVerificationEvidence: primary.is_verification_evidence === 1,
          downloadUrl: signedUrlByPath.get(primary.storage_path),
          createdAt: primary.created_at,
        }
      : null;

    attachVerificationToAscent(ascent);
  }

  return ascents;
}

// Aquesta funció valida les notes opcionals d’una ascensió.
// Permet deixar-les buides i limita la longitud quan s’envia text.
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
// Valida les dades, comprova la propietat dels recursos i coordina models relacionats.
const AscentService = {

  // Retorna totes les ascensions de l’usuari autenticat.
  // Cada registre inclou la foto principal i la informació de verificació si existeixen.
  async getByUser(userId) {
    const ascents = await AscentModel.findAllByUserId(userId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna les ascensions de l’usuari sobre un cim concret.
  // Aquesta informació permet mostrar l’historial personal dins del detall del cim.
  async getByUserAndPeak(userId, peakId) {
    const parsedPeakId = requireInteger(peakId, 'peakId');
    const ascents = await AscentModel.findAllByUserAndPeak(userId, parsedPeakId);
    return attachPrimaryPhotoToAscents(ascents);
  },

  // Retorna totes les fotos d’una ascensió concreta.
  // Abans de consultar-les, comprova que l’ascensió pertanyi a l’usuari.
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

  // Afegeix fotos normals a una ascensió existent.
  // Valida propietat, límit d’imatges i existència real dels fitxers pujats.
  async addPhotosToAscent(userId, ascentId, photos) {
    const parsedAscentId = requireInteger(ascentId, 'ascentId');

    const existing = await AscentModel.findByIdAndUserId(userId, parsedAscentId);
    if (!existing) {
      const error = new Error('Ascent not found');
      error.statusCode = 404;
      throw error;
    }

    const existingPhotos = await AscentPhotoModel.findAllByAscentIdAndUserId(
      parsedAscentId,
      userId
    );

    const validatedPhotos = ensureValidPhotosPayload(userId, photos);

    if (existingPhotos.length + validatedPhotos.length > MAX_PHOTOS_PER_ASCENT) {
      throw badRequest(`Invalid photos: at most ${MAX_PHOTOS_PER_ASCENT} per ascent`);
    }

    const normalizedPhotos = normalizeAdditionalPhotosPayload(
      existingPhotos,
      validatedPhotos
    );

    await ensurePhotosExistInBucket(normalizedPhotos);

    const createdPhotos = await AscentPhotoModel.createMany(
      parsedAscentId,
      normalizedPhotos
    );

    return Promise.all(
      createdPhotos.map(async (photo) => {
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

  // Crea una nova ascensió per a l’usuari autenticat.
  // També pot associar fotos i marcar el cim com a assolit.
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
  // La data queda bloquejada perquè forma part de la prova de verificació.
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

    // La data oficial de l’ascensió la fixa el servidor.
    // Això evita que una hora incorrecta del dispositiu alteri estadístiques o reptes.
    const ascentDate = new Date().toISOString().slice(0, 10);

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

  // Actualitza una ascensió existent de l’usuari autenticat.
  // Només modifica els camps enviats i manté protegides les ascensions alienes.
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

  // Elimina una ascensió de l’usuari autenticat.
  // També intenta netejar les fotos associades i recalcular els estats afectats.
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