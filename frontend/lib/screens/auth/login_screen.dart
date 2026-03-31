// login_screen.dart
// Responsabilidad: Pantalla de login.
// Widget: StatefulWidget (gestiona TextEditingControllers del formulario)
// Consume: AuthProvider para autenticar al usuario
// Funcionalidad: formulario de email y contraseña, botón de login,
// enlaces a registro y recuperación de contraseña.

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login Screen'),
      ),
    );
  }
}
