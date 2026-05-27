import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/region.dart';

// Aquest cas d’ús encapsula la càrrega de comarques disponibles.
// Permet que els controllers obtinguin les dades territorials sense dependre directament de l’API.
class GetRegionsUseCase {
  const GetRegionsUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet recuperar les comarques a través del backend.
  // Això manté el cas d’ús separat de la implementació concreta de l’API.
  final ApiClient _apiClient;

  // Recupera la llista de comarques disponibles.
  // Retorna les dades preparades perquè la pantalla les pugui utilitzar en filtres o seleccions.
  Future<List<Region>> execute() {
    return _apiClient.getRegions();
  }
}