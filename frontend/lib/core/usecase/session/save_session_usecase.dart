import 'package:cims/core/client/session_storage.dart';

// Aquest cas d’ús desa la sessió després d’un login correcte.
// Permet conservar l’accés de l’usuari i restaurar-lo més endavant.
class SaveSessionUseCase {
  const SaveSessionUseCase({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  // Aquest servei permet guardar les dades de sessió de manera persistent.
  // Això manté el cas d’ús separat del sistema concret d’emmagatzematge.
  final SessionStorage _sessionStorage;

  // Desa el token i l’identificador de l’usuari.
  // Aquestes dades permeten mantenir la sessió activa entre usos de l’aplicació.
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
