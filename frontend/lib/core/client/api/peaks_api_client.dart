import 'package:cims/core/entity/peak.dart';

// Aquest contracte agrupa les operacions relacionades amb els cims.
abstract class PeaksApiClient {
  Future<List<Peak>> getPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  });

  Future<Peak> getPeakById(int peakId);
}
