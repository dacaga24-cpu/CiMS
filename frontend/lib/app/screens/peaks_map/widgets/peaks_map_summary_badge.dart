import 'package:flutter/material.dart';

// Aquest element mostra quants cims s’estan representant al mapa.
// Ajuda l’usuari a entendre el resultat de la cerca i dels filtres aplicats.
class PeaksMapSummaryBadge extends StatelessWidget {
  const PeaksMapSummaryBadge({
    super.key,
    required this.totalPeaks,
  });

  // Nombre total de cims visibles amb la cerca i els filtres actuals.
  final int totalPeaks;

  // Mostra una etiqueta informativa sobre el volum de cims representats.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        // Plural català: "1 cim" en singular, "X cims" en plural.
        totalPeaks == 1 ? '1 cim' : '$totalPeaks cims',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF17212B),
        ),
      ),
    );
  }
}
