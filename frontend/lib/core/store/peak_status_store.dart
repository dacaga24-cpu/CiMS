import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/foundation.dart';

// Aquest store centralitza els estats personals dels cims per a l'usuari actual.
// Existeix una única instància durant tota la vida de l'aplicació, viva dins
// d'AppSession, perquè qualsevol pantalla pugui llegir o modificar l'estat
// d'un cim sense haver de fer una nova petició al backend ni mantenir còpies
// locals que es puguin desincronitzar.
//
// Quan el detall d'un cim canvia un flag, l'escriu aquí i el catàleg s'actualitza
// automàticament gràcies a la notificació del ChangeNotifier. Així s'eliminen
// les recàrregues completes que abans es disparaven en tornar al catàleg.
class PeakStatusStore extends ChangeNotifier {
  final Map<int, PeakStatus> _statusesByPeakId = {};

  // Aquest mètode retorna l'estat conegut d'un cim, o null si encara no en
  // tenim cap registre. Els consumidors han de tractar el null com a "estat
  // buit" i mostrar-lo de manera neutra a la interfície.
  PeakStatus? getStatus(int peakId) => _statusesByPeakId[peakId];

  // Aquest mètode escriu o actualitza l'estat d'un cim concret i notifica
  // tots els listeners. Es fa servir tant per persistir respostes del backend
  // com per aplicar canvis optimistes des dels controllers.
  void setStatus(PeakStatus status) {
    _statusesByPeakId[status.peakId] = status;
    notifyListeners();
  }

  // Aquest mètode reemplaça tots els estats del store de cop. S'utilitza
  // després d'una càrrega massiva (per exemple, al carregar el catàleg) per
  // garantir que el store reflecteix exactament la realitat del backend.
  void setAll(Iterable<PeakStatus> statuses) {
    _statusesByPeakId
      ..clear()
      ..addEntries(statuses.map((s) => MapEntry(s.peakId, s)));
    notifyListeners();
  }

  // Aquest mètode buida el store. Es crida quan la sessió caduca o l'usuari
  // tanca sessió, perquè els estats personals d'un usuari mai han de quedar
  // visibles per a un altre que iniciï sessió després.
  void clear() {
    if (_statusesByPeakId.isEmpty) {
      return;
    }
    _statusesByPeakId.clear();
    notifyListeners();
  }
}
