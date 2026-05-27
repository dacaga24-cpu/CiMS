import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';

// Aquest cas d’ús encapsula la càrrega del detall d’un cim concret.
// Això permet que el controller no depengui directament del client API.
class GetPeakByIdUseCase {
  const GetPeakByIdUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet obtenir el detall del cim a través del backend.
  // Això manté el controller separat dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera el cim indicat a partir del seu identificador.
  // Retorna la informació completa necessària per construir la pantalla de detall.
  Future<Peak> execute(int peakId) {
    return _apiClient.getPeakById(peakId);
  }
}
