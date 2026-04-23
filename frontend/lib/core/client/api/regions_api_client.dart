import 'package:cims/core/entity/region.dart';

// Aquest contracte agrupa les operacions relacionades amb les comarques o regions.
abstract class RegionsApiClient {
  Future<List<Region>> getRegions();
}
