import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús encapsula la consulta de l’estat personal d’un cim concret.
// Permet que la pantalla de detall pugui carregar si el cim està completat,
// marcat com a objectiu o afegit com a preferit sense parlar directament amb l’API.
class GetPeakStatusUseCase {
  const GetPeakStatusUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<PeakStatus> execute(int peakId) {
    return _apiClient.getPeakStatus(peakId);
  }
}