import 'package:cims/core/entity/peak_hourly_weather.dart';
import 'package:cims/core/entity/peak_weather.dart';

// Aquest contracte defineix les operacions de l'API relacionades amb la
// previsió meteorològica per cim. Es manté en una interfície pròpia
// perquè el frontend pugui dependre del contracte (i mockejar-lo en
// tests) sense conèixer la implementació HTTP concreta.
abstract class WeatherApiClient {
  // Aquest mètode recupera la previsió diària d'un cim. days és opcional
  // i permet ajustar l'horitzó dins del rang acceptat pel backend
  // (actualment 1..10 dies). La pantalla de detall el crida amb days=7
  // per defecte; altres consumidors poden demanar més o menys segons
  // necessitin.
  Future<PeakWeather> getPeakDailyWeather(
    int peakId, {
    int? days,
  });

  // Aquest mètode recupera la previsió horària d'un cim per a una data
  // concreta. date és una cadena ISO YYYY-MM-DD; el backend la valida i
  // retorna 404 si està fora de l'horitzó de Google (240h). El detall
  // del cim el crida quan l'usuari desplega una píldora diària.
  Future<PeakHourlyWeather> getPeakHourlyWeather(
    int peakId,
    String date,
  );
}
