// stats_screen.dart
// Responsabilidad: Pantalla de estadísticas del usuario.
// Widget: StatelessWidget (el estado viene de los providers)
// Consume: PeakProvider y AscentProvider para calcular estadísticas
// Funcionalidad: total de cims completados, porcentaje de progreso,
// cims por comarca, altitud media, gráficos de progreso.

import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Stats Screen'),
      ),
    );
  }
}
