// peak_map_screen.dart
// Responsabilidad: Pantalla del mapa de cims.
// Widget: StatefulWidget (gestiona el estado del mapa: zoom, centro, marcadores)
// Consume: PeakProvider para obtener las coordenadas de los cims
// Funcionalidad: mapa interactivo con flutter_map mostrando los cims como marcadores,
// diferenciados por estado (completado, objetivo, pendiente).

import 'package:flutter/material.dart';

class PeakMapScreen extends StatefulWidget {
  const PeakMapScreen({super.key});

  @override
  State<PeakMapScreen> createState() => _PeakMapScreenState();
}

class _PeakMapScreenState extends State<PeakMapScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Peak Map Screen'),
      ),
    );
  }
}
