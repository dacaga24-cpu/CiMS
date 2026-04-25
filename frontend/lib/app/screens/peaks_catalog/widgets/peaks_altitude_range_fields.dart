import 'package:flutter/material.dart';

// Aquest widget agrupa els camps d’altura mínima i màxima.
// Permet limitar el catàleg a un rang concret d’altitud.
class PeaksAltitudeRangeFields extends StatelessWidget {
  const PeaksAltitudeRangeFields({
    super.key,
    required this.minAltitudeController,
    required this.maxAltitudeController,
  });

  // Aquests controladors mantenen els valors escrits per l’usuari
  // fins que el panell aplica els filtres al catàleg.
  final TextEditingController minAltitudeController;
  final TextEditingController maxAltitudeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: minAltitudeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura mínima',
              suffixText: 'm',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: maxAltitudeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura màxima',
              suffixText: 'm',
            ),
          ),
        ),
      ],
    );
  }
}