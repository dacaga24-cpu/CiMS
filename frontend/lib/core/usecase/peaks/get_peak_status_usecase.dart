import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús encapsula la consulta de l’estat personal d’un cim concret.
// Permet que la pantalla de detall mostri si el cim està completat, marcat com a objectiu o afegit com a preferit.
class GetPeakStatusUseCase {
  const GetPeakStatusUseCase(this._apiClient);

  // Aquest client permet obtenir l’estat del cim a través del backend.
  // Això manté la pantalla separada dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera l’estat personal d’un cim concret.
  // Retorna les marques actuals perquè la interfície pugui mostrar-les correctament.
  Future<PeakStatus> execute(int peakId) {
    return _apiClient.getPeakStatus(peakId);
  }
}
