import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peaks_page.dart';
import 'package:cims/core/entity/weather_condition.dart';

// Aquest contracte agrupa les operacions relacionades amb els cims.
abstract class PeaksApiClient {
  // Aquest mètode permet recuperar el catàleg de cims aplicant, si cal,
  // criteris de cerca o filtratge per adaptar el resultat al que necessita l’usuari.
  Future<List<Peak>> getPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  });

  // Aquest mètode recupera una pàgina concreta del catàleg de cims.
  // S’utilitza per carregar més resultats quan l’usuari baixa pel llistat.
  // weatherDate + weatherConditions han d'arribar junts; si en falta un,
  // el client els ignora per no fer una petició inconsistent.
  Future<PeaksPage> getPeaksPage({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    int page = 1,
    int pageSize = 50,
    String? weatherDate,
    Set<WeatherConditionType>? weatherConditions,
  });

  // Aquest mètode recupera els cims preparats per mostrar-los al mapa.
  // Utilitza un endpoint específic perquè el mapa necessita tots els marcadors disponibles.
  // Accepta filtres perquè el backend pugui resoldre comarca, cerca, altitud i clima.
  Future<List<Peak>> getMapPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? weatherDate,
    Set<WeatherConditionType>? weatherConditions,
  });

  // Aquest mètode recupera la informació completa d’un cim concret
  // a partir del seu identificador.
  Future<Peak> getPeakById(int peakId);
}
