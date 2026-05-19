// Aquesta interfície defineix el contracte mínim d’emmagatzematge de sessió.
// Serveix perquè l’aplicació pugui guardar, recuperar i eliminar la sessió
// sense dependre directament d’una implementació concreta.
abstract class SessionStorage {
  // Aquest mètode defineix el guardat de les dades bàsiques de la sessió
  // perquè es puguin recuperar més endavant.
  Future<void> saveSession({
    required String token,
    required int userId,
  });

  // Aquests mètodes defineixen la lectura de les dades guardades
  // i la comprovació o eliminació de la sessió actual.
  Future<String?> readToken();
  Future<int?> readUserId();
  Future<bool> hasSession();
  Future<void> clearSession();
}
