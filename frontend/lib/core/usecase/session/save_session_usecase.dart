import 'package:cims/core/client/session_storage.dart';

// Aquest cas d’ús encapsula el guardat de la sessió després d’un login correcte.
// Serveix per separar aquesta responsabilitat de la pantalla i reutilitzar-la
// des de qualsevol punt on calgui conservar l’accés de l’usuari.
class SaveSessionUseCase {
  const SaveSessionUseCase({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  // Aquest bloc guarda la dependència necessària per persistir
  // les dades de la sessió actual.
  final SessionStorage _sessionStorage;

  // Aquest mètode desa el token i l’identificador de l’usuari
  // perquè l’aplicació pugui restaurar la sessió més endavant.
  Future<void> execute({
    required String token,
    required int userId,
  }) {
    return _sessionStorage.saveSession(
      token: token,
      userId: userId,
    );
  }
}