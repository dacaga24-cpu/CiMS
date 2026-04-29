import 'package:flutter/foundation.dart';

// Aquest store notifica quan les estadístiques personals poden haver canviat.
// Serveix per mantenir sincronitzada la pantalla d’estadístiques després
// d’accions com registrar una nova ascensió.
class UserStatsRefreshStore extends ChangeNotifier {
  // Aquest mètode avisa les pantalles interessades que cal tornar
  // a consultar les estadístiques al backend.
  void notifyStatsChanged() {
    notifyListeners();
  }
}
