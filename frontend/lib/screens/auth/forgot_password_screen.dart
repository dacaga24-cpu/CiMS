// forgot_password_screen.dart
// Responsabilidad: Pantalla de recuperación de contraseña.
// Widget: StatefulWidget (gestiona TextEditingController del email)
// Consume: AuthProvider para iniciar la recuperación
// Funcionalidad: formulario con email, botón de enviar enlace de recuperación.

import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Forgot Password Screen'),
      ),
    );
  }
}
