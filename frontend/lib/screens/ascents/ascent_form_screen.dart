// ascent_form_screen.dart
// Responsabilidad: Pantalla del formulario para registrar/editar una ascensión.
// Widget: StatefulWidget (gestiona TextEditingControllers y DatePicker)
// Consume: AscentProvider para crear/actualizar ascensiones
// Funcionalidad: selector de cim, fecha, notas opcionales, botón de guardar.

import 'package:flutter/material.dart';

class AscentFormScreen extends StatefulWidget {
  const AscentFormScreen({super.key});

  @override
  State<AscentFormScreen> createState() => _AscentFormScreenState();
}

class _AscentFormScreenState extends State<AscentFormScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Ascent Form Screen'),
      ),
    );
  }
}
