import 'package:flutter/foundation.dart';

import '../../../core/usecase/session/has_saved_session_usecase.dart';

// Aquest bloc defineix els possibles destins de navegació de la pantalla inicial.
// Serveix per indicar cap a on s’ha d’enviar l’usuari un cop s’ha comprovat si té una sessió guardada.
enum AppStartDestination {
  none,
  login,
  dashboard,
}

// Aquest controlador gestiona la decisió inicial de navegació de l’aplicació.
// La seva funció és esperar el temps mínim de visualització de la pantalla inicial,
// comprovar si hi ha una sessió guardada i indicar si l’usuari ha d’anar al login o al dashboard.
class AppStartController extends ChangeNotifier {
  // El constructor rep el cas d’ús encarregat de comprovar si existeix una sessió guardada.
  // També permet definir quant de temps s’ha de mostrar com a mínim la pantalla inicial.
  AppStartController({
    required HasSavedSessionUseCase hasSavedSessionUseCase,
    this.minimumDisplayTime = const Duration(milliseconds: 1800),
  }) : _hasSavedSessionUseCase = hasSavedSessionUseCase;

  // Aquest bloc guarda els valors principals que necessita el controlador:
  // el cas d’ús de sessió, el temps mínim de pantalla inicial i el destí actual de navegació.
  final HasSavedSessionUseCase _hasSavedSessionUseCase;
  final Duration minimumDisplayTime;

  AppStartDestination _destination = AppStartDestination.none;
  AppStartDestination get destination => _destination;

  bool _disposed = false;

  // Aquest mètode inicia el procés de decisió.
  // Primer manté visible la pantalla inicial durant un temps breu i després comprova
  // si l’usuari ja té una sessió guardada per decidir la pantalla següent.
  Future<void> initialize() async {
    await Future.delayed(minimumDisplayTime);

    if (_disposed) return;

    final hasSession = await _hasSavedSessionUseCase.execute();

    if (_disposed) return;

    _destination = hasSession
        ? AppStartDestination.dashboard
        : AppStartDestination.login;

    notifyListeners();
  }

  // Aquest mètode reinicia el destí de navegació un cop la redirecció ja s’ha consumat.
  // Això evita que la mateixa navegació es torni a executar de manera accidental.
  void consumeNavigation() {
    _destination = AppStartDestination.none;
  }

  // Aquest mètode marca el controlador com a finalitzat abans de tancar-lo.
  // D’aquesta manera s’evita continuar fent comprovacions o canvis quan ja no toca.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
