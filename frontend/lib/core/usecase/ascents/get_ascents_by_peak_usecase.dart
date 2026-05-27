import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';

// Aquest cas d’ús recupera les ascensions de l’usuari autenticat associades a un cim.
// Permet mostrar l’historial personal dins del detall del cim.
class GetAscentsByPeakUseCase {
  const GetAscentsByPeakUseCase(this._apiClient);

  // Aquest client permet obtenir les ascensions a través del backend.
  // Això manté la pantalla separada dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera les ascensions registrades per a un cim concret.
  // Retorna la llista preparada perquè la interfície pugui mostrar l’historial.
  Future<List<Ascent>> call(int peakId) {
    return _apiClient.getAscentsByPeak(peakId);
  }
}
