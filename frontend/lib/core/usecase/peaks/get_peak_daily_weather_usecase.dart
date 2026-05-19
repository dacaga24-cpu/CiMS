import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_weather.dart';

// Aquest cas d'ús encapsula la càrrega de la previsió diària d'un cim.
// La pantalla de detall l'utilitza per pintar la card meteorològica sense
// dependre directament del client HTTP.
class GetPeakDailyWeatherUseCase {
  const GetPeakDailyWeatherUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client defineix el punt d'accés a les dades de l'API.
  // El cas d'ús només depèn del contracte, no de la implementació concreta.
  final ApiClient _apiClient;

  // Aquest mètode recupera la previsió diària del cim indicat. days és
  // opcional perquè el valor per defecte (7) viu al backend; quan el
  // cridant el passa, el contracte permet ajustar l'horitzó (1..10).
  Future<PeakWeather> execute(
    int peakId, {
    int? days,
  }) {
    return _apiClient.getPeakDailyWeather(
      peakId,
      days: days,
    );
  }
}
