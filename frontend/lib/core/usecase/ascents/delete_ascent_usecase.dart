import 'package:cims/core/client/api_client.dart';

// Aquest cas d’ús elimina una ascensió registrada.
// Manté la pantalla separada de la comunicació directa amb el backend.
class DeleteAscentUseCase {
  const DeleteAscentUseCase(this._apiClient);

  // Aquest client permet executar l’eliminació a través del backend.
  // Això evita que la pantalla conegui els detalls de la petició.
  final ApiClient _apiClient;

  // Elimina una ascensió concreta de l’usuari autenticat.
  // El backend actualitza els estats i dades relacionades si és necessari.
  Future<void> call(int ascentId) {
    return _apiClient.deleteAscent(ascentId);
  }
}
