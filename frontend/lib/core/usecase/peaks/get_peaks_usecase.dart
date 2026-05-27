import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';

// Aquest cas d’ús encapsula l’obtenció del catàleg de cims.
// Permet reutilitzar la mateixa operació en la càrrega inicial i en les cerques filtrades.
class GetPeaksUseCase {
  const GetPeaksUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet obtenir el catàleg a través del backend.
  // Això manté la pantalla i el controller separats dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera el catàleg de cims des del backend.
  // Els filtres opcionals permeten ajustar els resultats segons el context de la pantalla.
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
