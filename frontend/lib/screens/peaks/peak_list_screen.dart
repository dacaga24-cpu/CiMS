// peak_list_screen.dart
// Responsabilidad: Pantalla con la lista de cims.
// Widget: StatelessWidget (el estado viene del PeakProvider)
// Consume: PeakProvider para obtener la lista de cims
// Funcionalidad: lista scrollable de cims con búsqueda y filtros,
// navegación al detalle de cada cim.

import 'package:flutter/material.dart';

class PeakListScreen extends StatelessWidget {
  const PeakListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Peak List Screen'),
      ),
    );
  }
}
