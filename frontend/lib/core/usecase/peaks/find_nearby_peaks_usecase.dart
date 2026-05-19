import 'dart:math';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/nearby_peak_candidate.dart';

// Aquest cas d’ús calcula quins cims són realment propers a una ubicació capturada.
// Només retorna candidats dins d’un radi raonable perquè la verificació sigui coherent.
class FindNearbyPeaksUseCase {
  const FindNearbyPeaksUseCase(this._apiClient);

  final ApiClient _apiClient;

  static const double _earthRadiusMeters = 6371000;
  static const double _defaultMaxDistanceMeters = 500;

  // Aquest mètode carrega els cims amb coordenades i retorna els més propers.
  // Si només hi ha un cim dins del radi, només es mostra aquell; si n’hi ha més,
  // es retornen com a màxim els candidats més propers.
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

  double _toRadians(double value) {
    return value * pi / 180;
  }
}