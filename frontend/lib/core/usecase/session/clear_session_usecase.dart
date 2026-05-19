import 'package:cims/core/client/session_storage.dart';

// Aquest cas d’ús encapsula la neteja de la sessió quan l’usuari tanca sessió.
// Serveix per separar aquesta acció de la capa visual i reutilitzar-la
// des de diferents punts de l’aplicació.
class ClearSessionUseCase {
  const ClearSessionUseCase({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  // Aquest bloc guarda la dependència necessària per eliminar
  // les dades persistides de la sessió actual.
  final SessionStorage _sessionStorage;

  // Aquest mètode executa la neteja de la sessió guardada
  // perquè l’usuari deixi de tenir accés autenticat a l’aplicació.
  Future<void> execute() {
    return _sessionStorage.clearSession();
  }
}
