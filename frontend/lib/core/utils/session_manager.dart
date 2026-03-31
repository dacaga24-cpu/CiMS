// session_manager.dart
// Responsabilidad: Gestión del JWT en SharedPreferences.
// Permite guardar, recuperar y eliminar el token de sesión.
// NO contiene lógica de negocio ni llamadas HTTP.

// import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Guarda el JWT en SharedPreferences
  Future<void> saveToken(String token) async {}

  // Recupera el JWT de SharedPreferences, devuelve null si no existe
  Future<String?> getToken() async {
    return null;
  }

  // Elimina el JWT de SharedPreferences (logout)
  Future<void> clearToken() async {}
}
