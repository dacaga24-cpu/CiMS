import 'package:cims/core/entity/peak_status.dart';

// Aquest contracte defineix les operacions relacionades amb l’estat personal
// dels cims. Permet consultar l’estat complet i modificar només els estats
// manuals: objectiu i preferit.
abstract class PeakStatusApiClient {
  // Aquest mètode retorna tots els estats de cims associats a l’usuari actual.
  // Serà útil per mostrar tags i aplicar filtres dins del catàleg.
  Future<List<PeakStatus>> getUserPeakStatuses();

  // Aquest mètode retorna l’estat personal d’un cim concret.
  // S’utilitzarà principalment a la pantalla de detall del cim.
  Future<PeakStatus> getPeakStatus(int peakId);

  // Aquest mètode actualitza els estats manuals d’un cim concret.
  // El completat no s’envia perquè deriva de les ascensions registrades.
  Future<PeakStatus> updatePeakStatus({
    required int peakId,
    bool? isTarget,
    bool? isFavorite,
  });
}