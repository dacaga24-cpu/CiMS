import 'package:cims/core/entity/user_stats.dart';

// Aquest contracte defineix les operacions de l’API relacionades
// amb les estadístiques personals de l’usuari autenticat.
abstract class StatsApiClient {
  // Aquest mètode recupera el resum d’estadístiques de l’usuari.
  // El backend utilitza el token de sessió per saber de quin usuari
  // ha de calcular les dades.
  Future<UserStats> getUserStats();
}
