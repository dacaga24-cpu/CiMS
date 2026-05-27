import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';

// Aquest cas d’ús actualitza una ascensió existent.
// Permet modificar les notes i, només quan correspon, també la data.
class UpdateAscentUseCase {
  const UpdateAscentUseCase(this._apiClient);

  // Aquest client permet actualitzar l’ascensió a través del backend.
  // Això manté la pantalla separada dels detalls de la petició.
  final ApiClient _apiClient;

  // Envia les dades modificades d’una ascensió concreta.
  // El paràmetre includeAscentDate permet evitar canvis de data quan el registre la té bloquejada.
  Future<Ascent> call({
    required int ascentId,
    required DateTime? ascentDate,
    bool includeAscentDate = true,
    String? notes,
  }) {
    return _apiClient.updateAscent(
      ascentId: ascentId,
      ascentDate: ascentDate,
      includeAscentDate: includeAscentDate,
      notes: notes,
    );
  }
}
