import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_photo.dart';

// Aquest cas d’ús recupera les fotos associades a una ascensió existent.
// Permet que la pantalla d’edició mostri les imatges ja guardades al backend.
class GetAscentPhotosUseCase {
  const GetAscentPhotosUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode demana al backend totes les fotos d’una ascensió concreta.
  Future<List<AscentPhoto>> call(int ascentId) {
    return _apiClient.getAscentPhotos(ascentId);
  }
}