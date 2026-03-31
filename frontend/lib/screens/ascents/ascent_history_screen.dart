// ascent_history_screen.dart
// Responsabilidad: Pantalla del historial de ascensiones del usuario.
// Widget: StatelessWidget (el estado viene del AscentProvider)
// Consume: AscentProvider para obtener la lista de ascensiones del usuario
// Funcionalidad: lista cronológica de ascensiones con nombre del cim, fecha y notas.

import 'package:flutter/material.dart';

class AscentHistoryScreen extends StatelessWidget {
  const AscentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Ascent History Screen'),
      ),
    );
  }
}
