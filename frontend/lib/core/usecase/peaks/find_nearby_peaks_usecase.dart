import 'dart:math';

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/nearby_peak_candidate.dart';

// Aquest cas d’ús calcula quins cims són més propers a una ubicació capturada.
// Es farà servir després de fer la foto i obtenir la posició del dispositiu.
class FindNearbyPeaksUseCase {
  const FindNearbyPeaksUseCase(this._apiClient);

  final ApiClient _apiClient;

  static const double _earthRadiusMeters = 6371000;

  // Aquest mètode carrega els cims amb coordenades i retorna els més propers.
  // La pantalla podrà mostrar-los perquè l’usuari seleccioni quin cim vol verificar.
  Future<List<NearbyPeakCandidate>> call({
    required double latitude,
    required double longitude,
    int limit = 3,
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
        .toList()
      ..sort(
        (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
      );

    return candidates.take(limit).toList();
  }

  // Aquest mètode calcula la distància aproximada entre dues coordenades.
  // Permet ordenar els cims segons la proximitat a la ubicació capturada.
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