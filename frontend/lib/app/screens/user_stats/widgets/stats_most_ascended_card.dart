import 'package:cims/core/entity/user_stats.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra el cim que l’usuari ha repetit més vegades.
// Si encara no hi ha dades suficients, mostra un estat neutre.
class StatsMostAscendedCard extends StatelessWidget {
  const StatsMostAscendedCard({
    super.key,
    required this.mostAscendedPeak,
  });

  // Aquesta dada conté el cim amb més ascensions registrades per l’usuari.
  // Pot ser nul·la quan encara no hi ha historial suficient per calcular-la.
  final MostAscendedPeakStats? mostAscendedPeak;

  // Aquest mètode construeix la targeta del cim més repetit.
  // Mostra la informació real quan existeix i un missatge orientatiu quan encara no hi ha dades.
  @override
  Widget build(BuildContext context) {
    final peak = mostAscendedPeak;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _PeakAvatar(imageUrl: peak?.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MÉS COPS CORONAT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F5ADB),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  peak?.peakName.isNotEmpty == true
                      ? peak!.peakName
                      : 'Encara sense repeticions',
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF181818),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  peak == null
                      ? 'Registra ascensions per veure aquesta dada'
                      : '${peak.totalAscents} ascensions', //TODO: no mostra els números de les ascensions, revisar
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
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

// Aquest avatar mostra una imatge del cim si el backend la facilita.
// Si no hi ha imatge, es mostra una icona de muntanya.
class _PeakAvatar extends StatelessWidget {
  const _PeakAvatar({
    required this.imageUrl,
  });

  // Aquesta URL permet mostrar una imatge representativa del cim.
  // Si no està disponible o falla la càrrega, el widget utilitza una alternativa visual.
  final String? imageUrl;

  // Aquest mètode decideix si es mostra la imatge del cim o l’avatar per defecte.
  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _FallbackPeakAvatar(),
        ),
      );
    }

    return const _FallbackPeakAvatar();
  }
}

// Aquest widget ofereix una representació visual neutra quan no hi ha imatge del cim.
// Manté la targeta completa i coherent encara que el backend no enviï cap fotografia.
class _FallbackPeakAvatar extends StatelessWidget {
  const _FallbackPeakAvatar();

  // Aquest mètode construeix l’avatar per defecte amb una icona de muntanya.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.terrain_rounded,
        color: Color(0xFF0F5ADB),
        size: 28,
      ),
    );
  }
}
