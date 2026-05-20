import 'package:cims/core/entity/peak.dart';

// Aquesta entitat representa un cim proper a la ubicació capturada.
// Serveix per proposar a l’usuari quin cim vol verificar abans d’enviar l’ascensió.
class NearbyPeakCandidate {
  const NearbyPeakCandidate({
    required this.peak,
    required this.distanceMeters,
  });

  final Peak peak;
  final double distanceMeters;
}
