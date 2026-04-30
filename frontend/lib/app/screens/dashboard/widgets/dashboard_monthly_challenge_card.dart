import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra un repte mensual més petit i temporal.
// Complementa el repte principal amb un objectiu proper i fàcil de seguir.
class DashboardMonthlyChallengeCard extends StatelessWidget {
  const DashboardMonthlyChallengeCard({
    super.key,
    required this.challenge,
  });

  // Aquesta dada conté la informació del repte mensual que es mostrarà al dashboard.
  // Permet representar el títol, la descripció i el progrés actual de l’usuari.
  final MonthlyChallenge challenge;

  // Aquest mètode construeix la targeta del repte mensual amb el text descriptiu
  // i una barra visual que facilita entendre ràpidament el progrés assolit.
  @override
  Widget build(BuildContext context) {
    final progress = (challenge.percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 199, 164, 248),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title ?? 'Repte mensual',
                  style: const TextStyle(
                    color: Color(0xFF3B2A00),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description ??
                      '${challenge.current}/${challenge.target} ${challenge.unit}',
                  style: const TextStyle(
                    color: Color(0xFF7020E0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7020E0),
                    ),
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