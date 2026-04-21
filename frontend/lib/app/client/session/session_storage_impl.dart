import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cims/core/client/session_storage.dart';

// Aquesta classe resol la persistència real de la sessió a dispositiu.
// Guarda el token i l'identificador d'usuari perquè l'aplicació pugui
// restaurar l'accés sense obligar a fer login cada vegada.
class SessionStorageImpl implements SessionStorage {
  SessionStorageImpl({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  // Aquest objecte encapsula l’accés a l’emmagatzematge segur del dispositiu,
  // on es desa la informació sensible de la sessió.
  final FlutterSecureStorage _storage;

  // Aquestes claus identifiquen de manera estable on es guarda
  // cada dada de sessió dins de l’emmagatzematge segur.
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  @override
  Future<void> saveSession({
    required String token,
    required int userId,
  }) async {
    // Aquest mètode desa les dades mínimes de la sessió actual
    // perquè l’aplicació pugui recuperar l’accés més endavant.
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  @override
  Future<String?> readToken() {
    // Aquest mètode recupera el token guardat, que és la peça principal
    // per mantenir l’usuari autenticat davant del backend.
    return _storage.read(key: _tokenKey);
  }

  @override
  Future<int?> readUserId() async {
    // Aquest mètode recupera l’identificador de l’usuari guardat
    // i el converteix al format que necessita l’aplicació.
    final rawValue = await _storage.read(key: _userIdKey);
    if (rawValue == null) return null;
    return int.tryParse(rawValue);
  }

  @override
  Future<bool> hasSession() async {
    // Aquest mètode permet saber ràpidament si hi ha una sessió
    // disponible per intentar restaurar l’accés de l’usuari.
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> clearSession() async {
    // Aquest mètode elimina totes les dades persistides de la sessió
    // quan l’usuari tanca sessió o aquesta deixa de ser vàlida.
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }
}