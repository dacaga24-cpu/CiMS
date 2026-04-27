import 'package:cims/core/entity/peak_status.dart';

// Aquest contracte defineix les operacions relacionades amb l’estat personal
// dels cims. Permet consultar i modificar si un cim està completat,
// marcat com a objectiu o afegit com a preferit per l’usuari autenticat.
abstract class PeakStatusApiClient {
  // Aquest mètode retorna tots els estats de cims associats a l’usuari actual.
  // Serà útil per mostrar tags i aplicar filtres dins del catàleg.
  Future<List<PeakStatus>> getUserPeakStatuses();

  // Aquest mètode retorna l’estat personal d’un cim concret.
  // S’utilitzarà principalment a la pantalla de detall del cim.
  Future<PeakStatus> getPeakStatus(int peakId);

  // Aquest mètode actualitza l’estat personal d’un cim concret.
  // Només s’envien els camps que es volen modificar.
  Future<PeakStatus> updatePeakStatus({
    required int peakId,
    bool? isCompleted,
    bool? isTarget,
    bool? isFavorite,
  });
}