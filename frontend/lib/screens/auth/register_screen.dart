// register_screen.dart
// Responsabilidad: Pantalla de registro de nuevo usuario.
// Widget: StatefulWidget (gestiona TextEditingControllers del formulario)
// Consume: AuthProvider para registrar al usuario
// Funcionalidad: formulario con nombre, apellido, email, contraseña y confirmación.

import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Register Screen'),
      ),
    );
  }
}
