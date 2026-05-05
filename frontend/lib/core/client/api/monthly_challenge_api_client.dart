import 'package:cims/core/entity/dashboard_summary.dart';

// Aquest contracte defineix les operacions de l’API relacionades
// amb el repte mensual de l’usuari autenticat.
abstract class MonthlyChallengeApiClient {
  // Aquest mètode recupera el repte mensual actiu.
  // El backend calcula el progrés segons les ascensions registrades durant el mes en curs.
  Future<MonthlyChallenge> getCurrentMonthlyChallenge();
}
