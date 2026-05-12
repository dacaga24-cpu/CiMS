import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/weather_condition.dart';

// Aquest cas d’ús recupera els cims que s’han de mostrar al mapa.
// Se separa del catàleg perquè el mapa utilitza un endpoint propi sense paginació.
class GetMapPeaksUseCase {
  const GetMapPeaksUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Aquest mètode demana al backend la llista de cims preparada per al mapa.
  // Els filtres principals s’envien al backend perquè comarca, cerca i altitud
  // es resolguin amb les dades completes del servidor. Els paràmetres
  // meteorològics només són efectius quan tots dos arriben informats; la
  // pantalla fa la comprovació abans d'invocar aquest cas d'ús.
  Future<List<Peak>> execute({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? weatherDate,
    Set<WeatherConditionType>? weatherConditions,
  }) {
    return _apiClient.getMapPeaks(
      search: search,
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
      weatherDate: weatherDate,
      weatherConditions: weatherConditions,
    );
  }
}
