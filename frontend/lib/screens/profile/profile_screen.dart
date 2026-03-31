// profile_screen.dart
// Responsabilidad: Pantalla del perfil del usuario.
// Widget: StatelessWidget (el estado viene del AuthProvider)
// Consume: AuthProvider para obtener los datos del usuario
// Funcionalidad: muestra nombre, email, botón de logout,
// opciones de configuración de la cuenta.

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}
