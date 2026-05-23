import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peaks_page.dart';

// Aquest cas d’ús recupera una pàgina concreta del catàleg de cims.
// Permet implementar càrrega progressiva sense que la pantalla parli directament amb l’API.
class GetPeaksPageUseCase {
  const GetPeaksPageUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Aquest mètode demana al backend una pàgina del catàleg.
  // Els filtres i la cerca es mantenen perquè cada nova pàgina respecti el context actual.
  Future<PeaksPage> execute({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int pageSize = 50,
  }) {
    return _apiClient.getPeaksPage(
      search: search,
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
      status: status,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      pageSize: pageSize,
    );
  }
}
