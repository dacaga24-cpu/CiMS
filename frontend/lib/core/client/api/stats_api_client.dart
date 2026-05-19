import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/entity/user_stats.dart';

// Aquest contracte defineix les operacions de l’API relacionades
// amb les estadístiques personals de l’usuari autenticat.
abstract class StatsApiClient {
  // Aquest mètode recupera el resum d’estadístiques de l’usuari.
  // El rang temporal permet ajustar mètriques variables com els metres totals.
  Future<UserStats> getUserStats({
    String? range,
  });

  // Aquest mètode recupera les dades necessàries per construir el dashboard.
  Future<DashboardSummary> getDashboardSummary();
}
