import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/dashboard_summary.dart';

// Aquest cas d’ús recupera les dades necessàries per construir el dashboard.
// Permet que la pantalla treballi amb un resum preparat del progrés de l’usuari.
class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase(this._apiClient);

  // Aquest client permet obtenir les dades del dashboard a través del backend.
  // El cas d’ús depèn del contracte de l’API, no de la seva implementació concreta.
  final ApiClient _apiClient;

  // Demana el resum principal del dashboard i hi afegeix el repte mensual actual.
  // Si el repte no es pot carregar, es conserva el dashboard base perquè la pantalla continuï funcionant.
  Future<DashboardSummary> execute() async {
    final dashboard = await _apiClient.getDashboardSummary();

    try {
      final monthlyChallenge = await _apiClient.getCurrentMonthlyChallenge();
      return dashboard.copyWith(monthlyChallenge: monthlyChallenge);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        rethrow;
      }

      return dashboard;
    }
  }
}