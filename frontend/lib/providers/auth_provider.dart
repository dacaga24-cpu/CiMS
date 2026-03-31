// auth_provider.dart
// Responsabilidad: Gestión del estado de autenticación.
// Extiende ChangeNotifier para notificar a los widgets consumidores.
// Delega las llamadas HTTP al AuthService.
// NO contiene lógica HTTP directa.

import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  // Estado
  // User? _currentUser;
  // bool _isLoading = false;
  // String? _error;
  // bool _isAuthenticated = false;

  // Registra un nuevo usuario: llama a AuthService.register, guarda el token
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {}

  // Autentica un usuario: llama a AuthService.login, guarda el token
  Future<void> login({required String email, required String password}) async {}

  // Cierra la sesión: llama a AuthService.logout, limpia el token
  Future<void> logout() async {}

  // Inicia recuperación de contraseña: llama a AuthService.forgotPassword
  Future<void> forgotPassword(String email) async {}

  // Comprueba si hay una sesión activa al arrancar la app
  Future<void> checkAuthStatus() async {}
}
