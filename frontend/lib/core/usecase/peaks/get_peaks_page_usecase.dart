import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peaks_page.dart';
import 'package:cims/core/entity/weather_condition.dart';

// Aquest cas d’ús recupera una pàgina concreta del catàleg de cims.
// Permet implementar càrrega progressiva sense que la pantalla parli directament amb l’API.
class GetPeaksPageUseCase {
  const GetPeaksPageUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Aquest mètode demana al backend una pàgina del catàleg.
  // Els filtres i la cerca es mantenen perquè cada nova pàgina respecti el context actual.
  // Els paràmetres meteorològics només són efectius quan tots dos arriben
  // informats: si el cridant en passa només un, el backend rebutjaria la
  // petició amb 400. Per això les pantalles fan el check abans i el
  // segon paràmetre arriba buit quan no hi ha filtre actiu.
  Future<PeaksPage> execute({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    int page = 1,
    int pageSize = 50,
    String? weatherDate,
    Set<WeatherConditionType>? weatherConditions,
  }) {
    return _apiClient.getPeaksPage(
      search: search,
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
      page: page,
      pageSize: pageSize,
      weatherDate: weatherDate,
      weatherConditions: weatherConditions,
    );
  }
}
