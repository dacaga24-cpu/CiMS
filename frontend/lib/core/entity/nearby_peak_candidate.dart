import 'package:cims/core/entity/peak.dart';

// Aquesta entitat representa un cim proper a la ubicació capturada.
// Serveix per proposar a l’usuari quin cim pot verificar abans d’enviar l’ascensió.
class NearbyPeakCandidate {
  const NearbyPeakCandidate({
    required this.peak,
    required this.distanceMeters,
  });

  // Aquestes dades relacionen el cim amb la distància respecte a l’usuari.
  // Permeten ordenar i mostrar els candidats més propers durant la verificació.
  final Peak peak;
  final double distanceMeters;
}