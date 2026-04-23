import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla queda preparada com a placeholder del detall del cim.
// No implementa encara la lògica ni les dades completes per no avançar una tasca futura.
@RoutePage()
class PeakDetailScreen extends StatelessWidget {
  const PeakDetailScreen({
    super.key,
    required this.peakId,
  });

  final int peakId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('TO DO: peak detail'),
      ),
    );
  }
}
