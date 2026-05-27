import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';

// Aquest cas d’ús recupera els cims que s’han de mostrar al mapa.
// Se separa del catàleg perquè el mapa utilitza un endpoint propi sense paginació.
class GetMapPeaksUseCase {
  const GetMapPeaksUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet obtenir els cims del mapa a través del backend.
  // Això manté la pantalla separada dels detalls de la petició.
  final ApiClient _apiClient;

  // Aquest mètode demana al backend la llista de cims preparada per al mapa.
  // Els filtres principals s’envien perquè la resposta sigui coherent amb la vista del catàleg.
  Future<List<Peak>> execute({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
  }) {
    return _apiClient.getMapPeaks(
      search: search,
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
      status: status,
    );
  }
}
