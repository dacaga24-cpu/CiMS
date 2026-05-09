import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús elimina una ascensió registrada.
// Manté la pantalla separada de la comunicació directa amb el backend.
class DeleteAscentUseCase {
  const DeleteAscentUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<void> call(int ascentId) {
    return _apiClient.deleteAscent(ascentId);
  }
}