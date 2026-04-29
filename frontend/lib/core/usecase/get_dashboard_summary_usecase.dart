import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/dashboard_summary.dart';

// Aquest cas d’ús recupera les dades necessàries per construir el dashboard.
// Consumeix el client d’API perquè la pantalla treballi amb dades reals del backend.
class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase(this._apiClient);

  // Aquest client defineix el punt d’accés a les dades de l’API.
  // El cas d’ús només depèn del contracte, no de la implementació concreta.
  final ApiClient _apiClient;

  // Aquest mètode demana al backend el resum complet del dashboard.
  // Manté la pantalla separada de la comunicació directa amb l’API.
  Future<DashboardSummary> execute() {
    return _apiClient.getDashboardSummary();
  }
}