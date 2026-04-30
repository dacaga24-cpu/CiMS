import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra el progrés principal del repte dels 100 cims.
// És el bloc visual més important del dashboard perquè resumeix l’objectiu global de l’usuari.
class DashboardChallengeCard extends StatelessWidget {
  const DashboardChallengeCard({
    super.key,
    required this.challenge,
    required this.onViewStats,
  });

  // Aquestes dades defineixen l’estat actual del repte i l’acció per consultar-ne més detall.
  // Permeten mostrar el progrés de l’usuari i navegar cap a la pantalla d’estadístiques.
  final ChallengeProgress challenge;
  final VoidCallback onViewStats;

  // Aquest mètode construeix la targeta visual del repte amb el percentatge completat,
  // una barra de progrés i un accés directe a les estadístiques.
  @override
  Widget build(BuildContext context) {
    final progress = (challenge.percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0E63F4),
            Color(0xFF0047C7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repte 100 Cims',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${challenge.completed} de ${challenge.target} cims completats',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${challenge.percentage}% completat · ${challenge.remaining} pendents',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewStats,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Veure estadístiques'),
            ),
          ),
        ],
      ),
    );
  }
}