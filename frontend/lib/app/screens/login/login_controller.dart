import 'package:flutter/material.dart';

enum LoginNavigationDestination {
  none,
  register,
}

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  LoginNavigationDestination _destination = LoginNavigationDestination.none;
  LoginNavigationDestination get destination => _destination;

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
    _destination = LoginNavigationDestination.register;
    notifyListeners();
  }

  void consumeNavigation() {
    _destination = LoginNavigationDestination.none;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
