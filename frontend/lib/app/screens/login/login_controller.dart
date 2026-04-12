import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void onLoginTap() {
    // TODO: integrar amb backend en una tasca futura
  }

  void onForgotPasswordTap() {
    // TODO: implementar en una tasca futura
  }

  void onRegisterTap() {
    // TODO: navegar a registre en una tasca futura
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}