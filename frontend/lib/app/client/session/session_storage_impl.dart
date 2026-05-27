import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cims/core/client/session_storage.dart';

// Aquesta classe resol la persistència real de la sessió al dispositiu.
// Guarda les dades necessàries per restaurar l’accés sense repetir el login.
class SessionStorageImpl implements SessionStorage {
  SessionStorageImpl({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  // Aquest objecte permet accedir a l’emmagatzematge segur del dispositiu.
  // S’hi desa informació sensible vinculada a la sessió de l’usuari.
  final FlutterSecureStorage _storage;

  // Aquestes claus identifiquen on es guarden les dades de sessió.
  // Permeten llegir, actualitzar o eliminar el token i l’identificador d’usuari.
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  // Desa les dades mínimes de la sessió actual.
  // Això permet recuperar l’accés de l’usuari en futures obertures de l’aplicació.
  @override
  Future<void> saveSession({
    required String token,
    required int userId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  // Recupera el token guardat de la sessió.
  // Aquest valor permet autenticar les peticions protegides al backend.
  @override
  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  // Recupera l’identificador de l’usuari guardat.
  // El valor es converteix a enter perquè la resta de l’aplicació el pugui utilitzar.
  @override
  Future<int?> readUserId() async {
    final rawValue = await _storage.read(key: _userIdKey);
    if (rawValue == null) return null;
    return int.tryParse(rawValue);
  }

  // Comprova si hi ha una sessió disponible.
  // Serveix per decidir si l’aplicació pot intentar restaurar l’accés automàticament.
  @override
  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  // Elimina totes les dades persistides de la sessió.
  // S’utilitza quan l’usuari tanca sessió o quan el token deixa de ser vàlid.
  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }
}
