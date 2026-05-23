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
  //
  // `status` és el filtre per l'estat personal del cim
  // (`pending|completed|target|favorite`). Requereix sessió: la
  // implementació envia el token JWT si està disponible i el backend
  // l'ignora si no ho està.
  //
  // `sortBy` accepta `altitude` o `name` (default backend: `altitude`).
  // `sortOrder` accepta `asc` o `desc` (default backend: `desc`).
  // Els dos paràmetres treballen sempre junts: el backend els valida i
  // construeix l'ORDER BY a partir de la combinació.
  //
  // Només afecten el catàleg; el mapa manté sempre l'ordre estable
  // del backend perquè l'ordre no afecta el render dels marcadors.
  Future<PeaksPage> getPeaksPage({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int pageSize = 50,
  });

  // Aquest mètode recupera els cims preparats per mostrar-los al mapa.
  // Utilitza un endpoint específic perquè el mapa necessita tots els marcadors disponibles.
  // Accepta filtres perquè el backend pugui resoldre comarca, cerca, altitud i estat.
  Future<List<Peak>> getMapPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    String? status,
  });

  // Aquest mètode recupera la informació completa d’un cim concret
  // a partir del seu identificador.
  Future<Peak> getPeakById(int peakId);
}
