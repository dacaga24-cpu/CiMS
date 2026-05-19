import 'package:cims/core/util/format.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra els metres acumulats dins del rang temporal seleccionat.
// Representa una mètrica motivacional vinculada a les ascensions registrades.
class StatsTotalMetersCard extends StatelessWidget {
  const StatsTotalMetersCard({
    super.key,
    required this.totalMeters,
    required this.comparisonLabel,
  });

  // Aquestes dades permeten mostrar el desnivell acumulat i el rang temporal aplicat.
  // Ajuden l’usuari a interpretar el seu progrés més enllà del nombre d’ascensions.
  final int totalMeters;
  final String comparisonLabel;

  // Aquest mètode construeix la targeta destacada dels metres acumulats.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F61E8),
            Color(0xFF084ED2),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F61E8),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.landscape_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // Aquest bloc agrupa la mètrica principal i el text del rang temporal.
          // Dona prioritat visual als metres perquè és la dada més rellevant.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'METRES ACUMULATS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD7E6FF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatAltitude(totalMeters),
                  style: const TextStyle(
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comparisonLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD7E6FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
