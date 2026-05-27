import 'package:cims/core/client/session_storage.dart';

// Aquest cas d’ús comprova si hi ha una sessió guardada.
// Permet decidir si l’aplicació pot restaurar l’accés de l’usuari automàticament.
class HasSavedSessionUseCase {
  const HasSavedSessionUseCase({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  // Aquest servei permet consultar les dades de sessió persistides.
  // Això manté el cas d’ús separat del sistema concret d’emmagatzematge.
  final SessionStorage _sessionStorage;

  // Comprova si hi ha una sessió disponible.
  // Retorna el resultat perquè l’aplicació decideixi si pot continuar sense login.
  Future<bool> execute() {
    return _sessionStorage.hasSession();
  }
}
