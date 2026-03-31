// auth_service.dart
// Responsabilidad: Llamadas HTTP a los endpoints de autenticación.
// NO contiene lógica de negocio ni gestión de estado.

// import 'package:http/http.dart' as http;
// import '../core/constants/api_constants.dart';

class AuthService {
  // POST /api/auth/register — Registra un nuevo usuario
  // Envía: { firstName, lastName, email, password }
  // Devuelve: datos del usuario creado + token JWT
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  // POST /api/auth/login — Autentica un usuario
  // Envía: { email, password }
  // Devuelve: datos del usuario + token JWT
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  // POST /api/auth/logout — Cierra la sesión
  // Envía: token en header Authorization
  Future<void> logout(String token) async {
    throw UnimplementedError();
  }

  // POST /api/auth/forgot-password — Inicia recuperación de contraseña
  // Envía: { email }
  Future<void> forgotPassword(String email) async {
    throw UnimplementedError();
  }
}
