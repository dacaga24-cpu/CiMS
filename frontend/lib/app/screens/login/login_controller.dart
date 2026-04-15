import 'package:flutter/material.dart';

import '../../../core/client/api_client.dart';
import '../../client/api/api_client_impl.dart';

enum LoginNavigationDestination {
  none,
  register,
  dashboard,
}

class LoginController extends ChangeNotifier {
  LoginController({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClientImpl();

  final ApiClient _apiClient;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool showValidation = false;
  bool isLoading = false;
  String? errorMessage;

  bool _disposed = false;

  LoginNavigationDestination _destination = LoginNavigationDestination.none;
  LoginNavigationDestination get destination => _destination;

  bool get hasInvalidEmail =>
      showValidation &&
      emailController.text.trim().isNotEmpty &&
      !_isValidEmail(emailController.text.trim());

  bool get hasEmptyPassword =>
      showValidation && passwordController.text.isEmpty;

  bool get canSubmit =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      _isValidEmail(emailController.text.trim());

  void onEmailChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> onLoginTap() async {
    if (isLoading) return;

    showValidation = true;
    errorMessage = null;
    notifyListeners();

    if (!canSubmit) return;

    isLoading = true;
    notifyListeners();

    try {
      await _apiClient.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      _destination = LoginNavigationDestination.dashboard;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        errorMessage = 'Credencials incorrectes';
      } else if (error.statusCode == 400) {
        errorMessage = 'Revisa les dades introduïdes';
      } else {
        errorMessage = error.message;
      }
    } catch (_) {
      errorMessage = 'No s\'ha pogut iniciar sessió';
    } finally {
      isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  void onForgotPasswordTap() {}

  void onRegisterTap() {
    _destination = LoginNavigationDestination.register;
    notifyListeners();
  }

  void consumeNavigation() {
    _destination = LoginNavigationDestination.none;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    _disposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}