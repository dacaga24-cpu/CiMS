import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús encapsula la consulta de tots els estats personals de l’usuari.
// Serà útil per mostrar indicadors dins del catàleg i aplicar filtres per cims
// completats, objectius, preferits o pendents.
class GetUserPeakStatusesUseCase {
  const GetUserPeakStatusesUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PeakStatus>> execute() {
    return _apiClient.getUserPeakStatuses();
  }
}
