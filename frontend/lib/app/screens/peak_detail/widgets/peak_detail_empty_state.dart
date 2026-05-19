import 'package:flutter/material.dart';

// Aquest widget mostra l’estat buit del detall del cim.
// S’utilitza quan la càrrega no retorna cap informació útil del cim seleccionat.
class PeakDetailEmptyState extends StatelessWidget {
  const PeakDetailEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No s\'ha trobat informació del cim'),
    );
  }
}
