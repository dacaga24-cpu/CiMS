import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user_stats.dart';

// Aquest cas d’ús encapsula la consulta de les estadístiques personals.
// El controller de la pantalla l’utilitzarà per carregar les dades sense
// dependre directament del client HTTP.
class GetUserStatsUseCase {
  const GetUserStatsUseCase(this._apiClient);

  // Aquest client defineix el punt d’accés a les dades de l’API.
  // El cas d’ús només depèn del contracte, no de la implementació concreta.
  final ApiClient _apiClient;

  // Aquest mètode executa la consulta de les estadístiques de l’usuari.
  // Retorna una entitat UserStats ja preparada per ser utilitzada pel controller.
  Future<UserStats> execute() {
    return _apiClient.getUserStats();
  }
}
