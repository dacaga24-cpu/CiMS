import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo.dart';

// Aquest cas d’ús recupera les fotos associades a una ascensió existent.
// Permet que la pantalla d’edició mostri les imatges ja guardades al backend.
class GetAscentPhotosUseCase {
  const GetAscentPhotosUseCase(this._apiClient);

  // Aquest client permet obtenir les fotos a través del backend.
  // Això manté la pantalla separada dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera totes les fotos d’una ascensió concreta.
  // Retorna la llista preparada perquè la interfície pugui mostrar-la.
  Future<List<AscentPhoto>> call(int ascentId) {
    return _apiClient.getAscentPhotos(ascentId);
  }
}
