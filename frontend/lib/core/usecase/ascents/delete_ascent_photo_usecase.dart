import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús elimina una foto associada a una ascensió.
// Manté la pantalla separada de la comunicació directa amb el backend.
class DeleteAscentPhotoUseCase {
  const DeleteAscentPhotoUseCase(this._apiClient);

  // Aquest client permet executar l’eliminació a través del backend.
  // Això evita que la pantalla conegui els detalls de la petició.
  final ApiClient _apiClient;

  // Elimina una foto concreta d’una ascensió.
  // El backend valida que la imatge pertanyi a l’usuari autenticat.
  Future<void> call(int photoId) {
    return _apiClient.deleteAscentPhoto(photoId);
  }
}
