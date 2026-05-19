import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';

// Aquest cas d'ús encapsula la consulta de la previsió horària d'un cim
// per a un dia concret. El controller del detall l'invoca quan l'usuari
// desplega una píldora del carrusel diari.
class GetPeakHourlyWeatherUseCase {
  const GetPeakHourlyWeatherUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Aquest mètode recupera la previsió horària per al cim i la data
  // indicats. La data ha d'arribar en format ISO YYYY-MM-DD; la
  // validació canònica viu al backend.
  Future<PeakHourlyWeather> execute(int peakId, String date) {
    return _apiClient.getPeakHourlyWeather(peakId, date);
  }
}
