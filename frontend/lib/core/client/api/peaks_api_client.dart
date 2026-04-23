import 'package:cims/core/entity/peak.dart';

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

  // Aquest mètode recupera la informació completa d’un cim concret
  // a partir del seu identificador.
  Future<Peak> getPeakById(int peakId);
}
