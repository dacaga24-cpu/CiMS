import 'package:cims/core/entity/region.dart';

// Aquest contracte agrupa les operacions relacionades amb les comarques o regions.
abstract class RegionsApiClient {
  // Aquest mètode recupera el llistat de regions disponibles
  // perquè l’aplicació les pugui mostrar o utilitzar en filtres.
  Future<List<Region>> getRegions();
}
