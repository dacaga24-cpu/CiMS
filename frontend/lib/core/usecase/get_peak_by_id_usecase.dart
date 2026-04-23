import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';

// Aquest cas d’ús encapsula la càrrega del detall d’un cim concret.
// Això permet que el controller no depengui directament del client API.
class GetPeakByIdUseCase {
  const GetPeakByIdUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Aquest mètode recupera el cim indicat a partir del seu identificador.
  Future<Peak> execute(int peakId) {
    return _apiClient.getPeakById(peakId);
  }
}