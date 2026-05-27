import 'dart:math';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/nearby_peak_candidate.dart';

// Aquest cas d’ús calcula quins cims són propers a una ubicació capturada.
// S’utilitza en la verificació d’ascensions per oferir només candidats coherents amb la posició de l’usuari.
class FindNearbyPeaksUseCase {
  const FindNearbyPeaksUseCase(this._apiClient);

  // Aquest client permet obtenir els cims amb coordenades des del backend.
  // Això manté el càlcul de proximitat separat de la capa visual.
  final ApiClient _apiClient;

  // Aquestes constants defineixen els valors base del càlcul de distància.
  // El radi màxim limita els candidats a cims realment propers.
  static const double _earthRadiusMeters = 6371000;
  static const double _defaultMaxDistanceMeters = 500;

  // Aquest mètode carrega els cims amb coordenades i retorna els més propers.
  // Només inclou candidats dins del radi definit i els ordena per proximitat.
  Future<List<NearbyPeakCandidate>> call({
    required double latitude,
    required double longitude,
    int limit = 3,
    double maxDistanceMeters = _defaultMaxDistanceMeters,
  }) async {
    final peaks = await _apiClient.getMapPeaks();

    final candidates = peaks
        .where((peak) => peak.hasMapPosition)
        .map(
          (peak) => NearbyPeakCandidate(
            peak: peak,
            distanceMeters: _calculateDistanceMeters(
              latitude,
              longitude,
              peak.latitude!,
              peak.longitude!,
            ),
          ),
        )
        .where((candidate) => candidate.distanceMeters <= maxDistanceMeters)
        .toList()
      ..sort(
        (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
      );

    return candidates.take(limit).toList();
  }

  // Aquest mètode calcula la distància aproximada entre dues coordenades.
  // Permet ordenar i filtrar els cims segons la proximitat real a l’usuari.
  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final deltaLat = _toRadians(lat2 - lat1);
    final deltaLon = _toRadians(lon2 - lon1);

    final a = pow(sin(deltaLat / 2), 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            pow(sin(deltaLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  // Aquest mètode transforma graus a radians.
  // És necessari per aplicar el càlcul de distància entre coordenades.
  double _toRadians(double value) {
    return value * pi / 180;
  }
}
