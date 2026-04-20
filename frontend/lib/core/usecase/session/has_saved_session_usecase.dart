import 'package:cims/core/client/session_storage.dart';

// Aquest cas d’ús encapsula la comprovació d’una sessió guardada.
// Serveix per saber si l’aplicació pot intentar restaurar l’accés
// sense dependre directament de la capa de persistència.
class HasSavedSessionUseCase {
  const HasSavedSessionUseCase({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  // Aquest bloc guarda la dependència necessària per consultar
  // si existeix una sessió prèviament desada.
  final SessionStorage _sessionStorage;

  // Aquest mètode comprova si hi ha una sessió disponible
  // i retorna el resultat perquè la resta de l’aplicació pugui decidir com actuar.
  Future<bool> execute() {
    return _sessionStorage.hasSession();
  }
}