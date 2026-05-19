import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús elimina una foto associada a una ascensió.
// Manté la pantalla separada de la comunicació directa amb el backend.
class DeleteAscentPhotoUseCase {
  const DeleteAscentPhotoUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<void> call(int photoId) {
    return _apiClient.deleteAscentPhoto(photoId);
  }
}
