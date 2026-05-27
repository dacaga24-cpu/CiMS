import 'package:cims/core/client/session_storage.dart';

// Aquest cas d’ús encapsula la neteja de la sessió.
// Permet tancar l’accés autenticat de l’usuari des de diferents punts de l’aplicació.
class ClearSessionUseCase {
  const ClearSessionUseCase({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  // Aquest servei permet eliminar les dades persistides de la sessió.
  // Això manté el cas d’ús separat del sistema concret d’emmagatzematge.
  final SessionStorage _sessionStorage;

  // Executa la neteja de la sessió guardada.
  // Després d’aquesta acció, l’usuari deixa de tenir accés autenticat.
  Future<void> execute() {
    return _sessionStorage.clearSession();
  }
}
