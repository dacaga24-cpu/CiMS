const { badRequest } = require('../utils/validation');

// Aquest límit defineix la distància màxima acceptada entre la ubicació capturada i el cim.
// Permet ajustar el criteri de verificació sense modificar la lògica principal.
const MAX_DEVICE_LOCATION_DISTANCE_METERS = Number(
  process.env.ASCENT_VERIFICATION_MAX_DISTANCE_METERS || 500
);

// Aquest límit defineix la precisió màxima acceptada de la ubicació del dispositiu.
// Si la precisió és baixa, la verificació queda pendent en lloc de rebutjar-se directament.
const MAX_DEVICE_LOCATION_ACCURACY_METERS = Number(
  process.env.ASCENT_VERIFICATION_MAX_ACCURACY_METERS || 100
);

// Aquesta constant representa el radi aproximat de la Terra en metres.
// S’utilitza per calcular la distància entre la ubicació capturada i el cim.
const EARTH_RADIUS_METERS = 6371000;

// Aquest mètode valida que una coordenada sigui numèrica i estigui dins del rang correcte.
// Evita guardar verificacions amb latituds o longituds impossibles.
function requireCoordinate(value, fieldName, { min, max }) {
  if (value === undefined || value === null || value === '') {
    throw badRequest(`Missing required field: ${fieldName}`);
  }

  const parsed = Number(value);

  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    throw badRequest(
      `Invalid ${fieldName}: must be a number between ${min} and ${max}`
    );
  }

  return parsed;
}

// Aquest mètode valida la precisió de la ubicació capturada.
// La precisió ajuda a decidir si la verificació és fiable o ha de quedar pendent.
function requireAccuracyMeters(value) {
  if (value === undefined || value === null || value === '') {
    throw badRequest('Missing required field: capturedAccuracyMeters');
  }

  const parsed = Number(value);

  if (!Number.isFinite(parsed) || parsed < 0) {
    throw badRequest('Invalid capturedAccuracyMeters: must be a positive number');
  }

  return parsed;
}

// Aquest mètode valida la data de captura enviada pel dispositiu.
// La data es conserva com a informació d’auditoria, però la data oficial de l’ascensió la fixa el servidor.
function requireCapturedAt(value) {
  if (value === undefined || value === null || value === '') {
    throw badRequest('Missing required field: capturedAt');
  }

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    throw badRequest('Invalid capturedAt: must be a valid date');
  }

  return parsed;
}

// Aquest mètode transforma graus a radians.
// És necessari per calcular la distància entre dues coordenades.
function toRadians(value) {
  return (value * Math.PI) / 180;
}

// Aquest mètode calcula la distància aproximada entre dues coordenades.
// Serveix per comprovar si l’usuari era prou a prop del cim en el moment de la captura.
function calculateDistanceMeters(lat1, lon1, lat2, lon2) {
  const deltaLat = toRadians(lat2 - lat1);
  const deltaLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(deltaLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(deltaLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return EARTH_RADIUS_METERS * c;
}

// Aquest mètode comprova que el cim tingui coordenades vàlides.
// Sense coordenades del cim no es pot validar la ubicació capturada per l’usuari.
function ensurePeakHasCoordinates(peak) {
  if (!peak) {
    const error = new Error('Peak not found');
    error.statusCode = 404;
    throw error;
  }

  const latitude = Number(peak.latitude);
  const longitude = Number(peak.longitude);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw badRequest('Peak does not have valid coordinates');
  }

  return { latitude, longitude };
}

// Aquest servei centralitza la lògica de verificació d’ascensions.
// Decideix si una evidència és vàlida, pendent o rebutjada sense dependre dels controladors.
const AscentVerificationService = {
  calculateDistanceMeters,

  // Aquest mètode valida les coordenades capturades contra el cim seleccionat.
  // Retorna la distància calculada i les dades normalitzades que després es desaran.
  validateCapturedCoordinatesAgainstPeak({
    peak,
    capturedLatitude,
    capturedLongitude,
    capturedAccuracyMeters,
    capturedAt,
  }) {
    const peakCoordinates = ensurePeakHasCoordinates(peak);

    const latitude = requireCoordinate(capturedLatitude, 'capturedLatitude', {
      min: -90,
      max: 90,
    });

    const longitude = requireCoordinate(capturedLongitude, 'capturedLongitude', {
      min: -180,
      max: 180,
    });

    const accuracyMeters = requireAccuracyMeters(capturedAccuracyMeters);
    const captureDate = requireCapturedAt(capturedAt);

    const distanceToPeakMeters = calculateDistanceMeters(
      latitude,
      longitude,
      peakCoordinates.latitude,
      peakCoordinates.longitude
    );

    return {
      capturedLatitude: latitude,
      capturedLongitude: longitude,
      capturedAccuracyMeters: accuracyMeters,
      capturedAt: captureDate,
      distanceToPeakMeters,
      maxAllowedDistanceMeters: MAX_DEVICE_LOCATION_DISTANCE_METERS,
      maxAllowedAccuracyMeters: MAX_DEVICE_LOCATION_ACCURACY_METERS,
    };
  },

  // Aquest mètode és el punt d’entrada general de la verificació.
  // Permet validar una ascensió sense que el controlador conegui els detalls de cada mètode.
  evaluateVerification({
    method,
    peak,
    capturedLatitude,
    capturedLongitude,
    capturedAccuracyMeters,
    capturedAt,
  }) {
    if (method === 'device_location') {
      return this.evaluateDeviceLocationVerification({
        peak,
        capturedLatitude,
        capturedLongitude,
        capturedAccuracyMeters,
        capturedAt,
      });
    }

    if (method === 'photo_exif') {
      return this.evaluatePhotoExifVerification();
    }

    if (method === 'manual') {
      return this.evaluateManualVerification();
    }

    throw badRequest('Invalid verification method');
  },

  // Aquest mètode avalua una verificació basada en la ubicació capturada pel dispositiu.
  // Retorna l’estat final, la distància al cim i el motiu de la decisió.
  evaluateDeviceLocationVerification({
    peak,
    capturedLatitude,
    capturedLongitude,
    capturedAccuracyMeters,
    capturedAt,
  }) {
    const validation = this.validateCapturedCoordinatesAgainstPeak({
      peak,
      capturedLatitude,
      capturedLongitude,
      capturedAccuracyMeters,
      capturedAt,
    });

    if (
      validation.capturedAccuracyMeters >
      validation.maxAllowedAccuracyMeters
    ) {
      return {
        method: 'device_location',
        status: 'pending',
        capturedLatitude: validation.capturedLatitude,
        capturedLongitude: validation.capturedLongitude,
        capturedAccuracyMeters: validation.capturedAccuracyMeters,
        capturedAt: validation.capturedAt,
        distanceToPeakMeters: validation.distanceToPeakMeters,
        checkedAt: new Date(),
        reason: 'LOCATION_ACCURACY_TOO_LOW',
      };
    }

    if (
      validation.distanceToPeakMeters <=
      validation.maxAllowedDistanceMeters
    ) {
      return {
        method: 'device_location',
        status: 'verified',
        capturedLatitude: validation.capturedLatitude,
        capturedLongitude: validation.capturedLongitude,
        capturedAccuracyMeters: validation.capturedAccuracyMeters,
        capturedAt: validation.capturedAt,
        distanceToPeakMeters: validation.distanceToPeakMeters,
        checkedAt: new Date(),
        reason: 'DEVICE_LOCATION_WITHIN_ALLOWED_DISTANCE',
      };
    }

    return {
      method: 'device_location',
      status: 'rejected',
      capturedLatitude: validation.capturedLatitude,
      capturedLongitude: validation.capturedLongitude,
      capturedAccuracyMeters: validation.capturedAccuracyMeters,
      capturedAt: validation.capturedAt,
      distanceToPeakMeters: validation.distanceToPeakMeters,
      checkedAt: new Date(),
      reason: 'DEVICE_LOCATION_TOO_FAR_FROM_PEAK',
    };
  },

  // Aquest mètode deixa preparat el flux de verificació per metadades EXIF.
  // La lectura real de metadades es completarà en una tasca específica.
  evaluatePhotoExifVerification() {
    return {
      method: 'photo_exif',
      status: 'pending',
      capturedLatitude: null,
      capturedLongitude: null,
      capturedAccuracyMeters: null,
      capturedAt: null,
      distanceToPeakMeters: null,
      checkedAt: null,
      reason: 'PHOTO_EXIF_NOT_IMPLEMENTED',
    };
  },

  // Aquest mètode deixa preparat el flux de revisió manual.
  // Permet representar verificacions que necessiten una validació posterior.
  evaluateManualVerification() {
    return {
      method: 'manual',
      status: 'pending',
      capturedLatitude: null,
      capturedLongitude: null,
      capturedAccuracyMeters: null,
      capturedAt: null,
      distanceToPeakMeters: null,
      checkedAt: null,
      reason: 'MANUAL_REVIEW_PENDING',
    };
  },
};

module.exports = AscentVerificationService;