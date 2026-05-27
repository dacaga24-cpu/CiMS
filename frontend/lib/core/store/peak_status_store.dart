import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/foundation.dart';

// Aquest store centralitza els estats personals dels cims de l’usuari actual.
// Permet compartir els canvis entre pantalles sense duplicar dades locals.
class PeakStatusStore extends ChangeNotifier {
  final Map<int, PeakStatus> _statusesByPeakId = {};

  // Retorna l’estat conegut d’un cim concret.
  // Si encara no s’ha carregat, retorna null perquè la interfície pugui mostrar un estat neutre.
  PeakStatus? getStatus(int peakId) => _statusesByPeakId[peakId];

  // Desa o actualitza l’estat d’un cim concret.
  // Després notifica les pantalles que depenen d’aquesta informació.
  void setStatus(PeakStatus status) {
    _statusesByPeakId[status.peakId] = status;
    notifyListeners();
  }

  // Marca un cim com a completat i verificat dins de l’estat compartit.
  // S’utilitza després de crear correctament una ascensió verificada.
  void markCompletedAndVerified(int peakId) {
    final currentStatus = getStatus(peakId) ?? PeakStatus.emptyForPeak(peakId);

    setStatus(
      currentStatus.copyWith(
        isCompleted: true,
        hasVerifiedAscent: true,
      ),
    );
  }

  // Reemplaça tots els estats guardats al store.
  // S’utilitza després d’una càrrega completa per sincronitzar les dades amb el backend.
  void setAll(Iterable<PeakStatus> statuses) {
    _statusesByPeakId
      ..clear()
      ..addEntries(statuses.map((s) => MapEntry(s.peakId, s)));
    notifyListeners();
  }

  // Buida tots els estats personals guardats.
  // S’utilitza quan la sessió es tanca o deixa de ser vàlida.
  void clear() {
    if (_statusesByPeakId.isEmpty) {
      return;
    }
    _statusesByPeakId.clear();
    notifyListeners();
  }
}