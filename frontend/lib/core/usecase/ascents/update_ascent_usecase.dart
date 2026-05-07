import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';

// Aquest cas d’ús actualitza una ascensió existent.
// Centralitza l’acció d’edició perquè la pantalla no depengui directament de l’API.
class UpdateAscentUseCase {
  const UpdateAscentUseCase(this._apiClient);

  final ApiClient _apiClient;

  // Aquest mètode envia al backend la data i les notes editades per l’usuari.
  Future<Ascent> call({
    required int ascentId,
    required DateTime ascentDate,
    String? notes,
  }) {
    return _apiClient.updateAscent(
      ascentId: ascentId,
      ascentDate: ascentDate,
      notes: notes,
    );
  }
}