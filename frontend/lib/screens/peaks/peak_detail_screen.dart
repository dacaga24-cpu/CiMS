// peak_detail_screen.dart
// Responsabilidad: Pantalla de detalle de un cim.
// Widget: StatelessWidget (el estado viene del PeakProvider)
// Consume: PeakProvider para obtener los datos del cim
// Funcionalidad: muestra nombre, altitud, comarca, coordenadas,
// estado (completado/favorito/objetivo), historial de ascensiones.

import 'package:flutter/material.dart';

class PeakDetailScreen extends StatelessWidget {
  const PeakDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Peak Detail Screen'),
      ),
    );
  }
}
