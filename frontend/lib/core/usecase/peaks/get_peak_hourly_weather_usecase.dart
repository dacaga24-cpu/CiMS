import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';

// Aquest cas d’ús encapsula la consulta de la previsió horària d’un cim.
// Permet carregar el detall meteorològic d’un dia concret sense dependre directament del client HTTP.
class GetPeakHourlyWeatherUseCase {
  const GetPeakHourlyWeatherUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client permet obtenir la previsió horària a través del backend.
  // Això manté el controller separat dels detalls de la petició.
  final ApiClient _apiClient;

  // Recupera la previsió horària del cim i la data indicats.
  // La data s’envia en format YYYY-MM-DD perquè el backend pugui filtrar el dia corresponent.
  Future<PeakHourlyWeather> execute(int peakId, String date) {
    return _apiClient.getPeakHourlyWeather(peakId, date);
  }
}
