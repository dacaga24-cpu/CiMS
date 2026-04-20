import 'package:flutter/material.dart';

// Aquest enum representa les possibles navegacions que la pantalla pot executar.
// La vista les consumeix i fa la navegació real des de fora del controller.
enum ProfileSettingsDestination {
  none,
  back,
  login,
}

// Aquest controller gestiona l’estat funcional bàsic de la pantalla.
// En aquesta iteració només es resol de manera real el tancament de sessió.
class ProfileSettingsController extends ChangeNotifier {
  ProfileSettingsController({
    required this.displayName,
    Future<void> Function()? logoutAction,
  }) : _logoutAction = logoutAction;

  // Aquest nom es mostra com a títol principal de la pantalla.
  final String displayName;

  // Aquesta acció permet connectar el logout amb la lògica real de sessió
  // quan ja estigui implementada al projecte.
  final Future<void> Function()? _logoutAction;

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProfileSettingsDestination _destination = ProfileSettingsDestination.none;
  ProfileSettingsDestination get destination => _destination;

  // Aquesta acció indica que l’usuari vol tornar enrere.
  void onBackTap() {
    _destination = ProfileSettingsDestination.back;
    notifyListeners();
  }

  // Aquesta acció resol el tancament de sessió de la pantalla.
  // Si en el futur hi ha persistència real, aquí és on s’haurà de netejar.
  Future<void> onLogoutTap() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_logoutAction != null) {
        await _logoutAction!();
      }

      _destination = ProfileSettingsDestination.login;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut tancar la sessió';
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  // Aquest mètode neteja la navegació pendent un cop la vista ja l’ha executada.
  void consumeNavigation() {
    _destination = ProfileSettingsDestination.none;
  }

  // Aquest mètode evita mostrar el mateix error més d’una vegada.
  void consumeErrorMessage() {
    _errorMessage = null;
  }
}