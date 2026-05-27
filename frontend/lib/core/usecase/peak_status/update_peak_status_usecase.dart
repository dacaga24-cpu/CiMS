import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús actualitza l’estat personal d’un cim.
// Només permet modificar marques manuals, com objectiu o preferit.
class UpdatePeakStatusUseCase {
  const UpdatePeakStatusUseCase(this._apiClient);

  // Aquest client permet enviar els canvis d’estat al backend.
  // Això manté les pantalles separades dels detalls de la petició.
  final ApiClient _apiClient;

  // Actualitza les marques manuals d’un cim concret.
  // Retorna l’estat actualitzat perquè la interfície pugui refrescar-se.
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
