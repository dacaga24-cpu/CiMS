import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';

// Aquest cas d’ús consulta tots els estats personals de l’usuari.
// Permet mostrar indicadors i aplicar filtres de cims completats, objectius, preferits o pendents.
class GetUserPeakStatusesUseCase {
  const GetUserPeakStatusesUseCase(this._apiClient);

  // Aquest client permet obtenir els estats personals a través del backend.
  // Això manté les pantalles separades dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera tots els estats personals dels cims de l’usuari autenticat.
  // Retorna la llista preparada perquè la interfície pugui utilitzar-la.
  Future<List<PeakStatus>> execute() {
    return _apiClient.getUserPeakStatuses();
  }
}
