import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús encapsula l’actualització de l’estat personal d’un cim.
// Només permet modificar els estats manuals, mantenint el completat com a
// informació derivada de les ascensions registrades.
class UpdatePeakStatusUseCase {
  const UpdatePeakStatusUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<PeakStatus> execute({
    required int peakId,
    bool? isTarget,
    bool? isFavorite,
  }) {
    return _apiClient.updatePeakStatus(
      peakId: peakId,
      isTarget: isTarget,
      isFavorite: isFavorite,
    );
  }
}
