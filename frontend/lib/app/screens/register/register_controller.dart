import 'package:flutter/material.dart';

import '../../../app/client/api/api_client_impl.dart';
import '../../../core/client/api_client.dart';

enum RegisterNavigationDestination {
  none,
  login,
  terms,
}

class RegisterController extends ChangeNotifier {
  RegisterController({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClientImpl();

  final ApiClient _apiClient;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool showValidation = false;
  bool isLoading = false;
  String? errorMessage;

  RegisterNavigationDestination _destination =
      RegisterNavigationDestination.none;
  RegisterNavigationDestination get destination => _destination;

  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  bool get hasPasswordMismatch =>
      showValidation &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      !passwordsMatch;

  bool get canSubmit =>
      firstNameController.text.trim().isNotEmpty &&
      lastNameController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      passwordsMatch &&
      _isValidEmail(emailController.text.trim()) &&
      passwordController.text.length >= 8;

  bool get hasInvalidEmail =>
      showValidation &&
      emailController.text.trim().isNotEmpty &&
      !_isValidEmail(emailController.text.trim());

  bool get hasShortPassword =>
      showValidation &&
      passwordController.text.isNotEmpty &&
      passwordController.text.length < 8;

  void onFirstNameChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onLastNameChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onEmailChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onConfirmPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> onCreateAccountTap() async {
    showValidation = true;
    errorMessage = null;
    notifyListeners();

    if (!canSubmit) return;

    isLoading = true;
    notifyListeners();

    try {
      await _apiClient.register(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      _destination = RegisterNavigationDestination.login;
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        errorMessage = 'Aquest correu ja està registrat';
      } else {
        errorMessage = error.message;
      }
    } catch (_) {
      errorMessage = 'No s\'ha pogut completar el registre';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onAlreadyHaveAccountTap() {
    _destination = RegisterNavigationDestination.login;
    notifyListeners();
  }

  void onTermsTap() {
    _destination = RegisterNavigationDestination.terms;
    notifyListeners();
  }

  void consumeNavigation() {
    _destination = RegisterNavigationDestination.none;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}