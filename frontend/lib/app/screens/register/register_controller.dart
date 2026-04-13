import 'package:flutter/material.dart';

class RegisterController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool showValidation = false;

  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  bool get hasPasswordMismatch =>
      showValidation &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      !passwordsMatch;

  bool get canSubmit =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      passwordsMatch;

  void onEmailChanged(String value) {
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    notifyListeners();
  }

  void onConfirmPasswordChanged(String value) {
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

  void onCreateAccountTap() {
    showValidation = true;
    notifyListeners();

    if (!canSubmit) return;

    // TODO: integrar amb backend en una tasca futura
  }

  void onAlreadyHaveAccountTap() {
    // TODO: navegar a login en una tasca futura
  }

  void onTermsTap() {
    // TODO: obrir pantalla o enllaç de termes del servei
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}