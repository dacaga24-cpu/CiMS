import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';

// Aquest cas d'ús encapsula l'obtenció del catàleg de cims.
// Serveix per separar la lògica de negoci de la pantalla i del controller,
// i per reutilitzar la mateixa operació tant en la càrrega inicial com en la cerca.
class GetPeaksUseCase {
  const GetPeaksUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Aquest mètode recupera el catàleg de cims des del backend.
  // Els filtres són opcionals i permeten mantenir una única entrada
  // per a la llista base i per a futures ampliacions del catàleg.
  Future<List<Peak>> execute({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  }) {
    return _apiClient.getPeaks(
      search: search,
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
    );
  }
}
