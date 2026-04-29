import 'package:flutter/material.dart';

// Aquesta targeta mostra els metres totals acumulats per l’usuari.
// Representa una mètrica motivacional vinculada a les ascensions registrades.
class StatsTotalMetersCard extends StatelessWidget {
  const StatsTotalMetersCard({
    super.key,
    required this.totalMeters,
    required this.comparisonLabel,
  });

  // Aquestes dades permeten mostrar el desnivell acumulat i una comparativa breu.
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
          const Icon(
            Icons.landscape_outlined,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 14),
          // Aquest bloc agrupa la mètrica principal i el text de comparativa.
          // Dona prioritat visual als metres totals perquè és la dada més rellevant.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Metres totals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD7E6FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(totalMeters)}m',
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comparisonLabel,
                  style: const TextStyle(
                    fontSize: 11,
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

  // Aquest mètode formata els metres amb separador de milers.
  // Facilita la lectura de valors acumulats grans dins de la targeta.
  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}
