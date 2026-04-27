import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús encapsula l’actualització de l’estat personal d’un cim.
// Permet modificar només els camps necessaris, mantenint la pantalla separada
// de la comunicació directa amb el backend.
class UpdatePeakStatusUseCase {
  const UpdatePeakStatusUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<PeakStatus> execute({
    required int peakId,
    bool? isCompleted,
    bool? isTarget,
    bool? isFavorite,
  }) {
    return _apiClient.updatePeakStatus(
      peakId: peakId,
      isCompleted: isCompleted,
      isTarget: isTarget,
      isFavorite: isFavorite,
    );
  }
}