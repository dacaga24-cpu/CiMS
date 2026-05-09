import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';

// Aquest cas d’ús actualitza una ascensió existent.
// Permet modificar les notes i conservar, canviar o deixar buida la data.
class UpdateAscentUseCase {
  const UpdateAscentUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<Ascent> call({
    required int ascentId,
    required DateTime? ascentDate,
    String? notes,
  }) {
    return _apiClient.updateAscent(
      ascentId: ascentId,
      ascentDate: ascentDate,
      notes: notes,
    );
  }
}