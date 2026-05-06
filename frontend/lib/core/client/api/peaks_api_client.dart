import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peaks_page.dart';

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
  Future<PeaksPage> getPeaksPage({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    int page = 1,
    int pageSize = 50,
  });

  // Aquest mètode recupera els cims preparats per mostrar-los al mapa.
  // Utilitza un endpoint específic perquè el mapa necessita tots els marcadors disponibles.
  Future<List<Peak>> getMapPeaks();

  // Aquest mètode recupera la informació completa d’un cim concret
  // a partir del seu identificador.
  Future<Peak> getPeakById(int peakId);
}
