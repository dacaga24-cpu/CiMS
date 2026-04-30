import 'package:flutter/material.dart';

// Aquesta targeta mostra el progrés del repte anual dels 100 cims.
// El càlcul del període correspon al backend: compta els ascensos dels últims
// 365 dies prenent com a referència l’última ascensió registrada per l’usuari.
class StatsChallengeCard extends StatelessWidget {
  const StatsChallengeCard({
    super.key,
    required this.current,
    required this.target,
    required this.percentage,
  });

  // Aquestes dades defineixen l’estat actual del repte anual.
  // El widget només les mostra; la lògica de càlcul del període es resol fora de la UI.
  final int current;
  final int target;
  final int percentage;

  // Aquest mètode construeix la targeta visual del repte i representa el progrés amb text i barra.
  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aquest bloc mostra el nom del repte i el percentatge anual assolit.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Repte 100 Cims',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8A2DFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Últims 365 dies segons el teu últim ascens',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF747B88),
            ),
          ),
          const SizedBox(height: 18),
          // Aquesta barra representa visualment l’avanç de l’usuari dins del repte anual.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE8E0FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8A2DFF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Aquest bloc resumeix el punt inicial, l’estat actual i l’objectiu anual del repte.
          Row(
            children: [
              const Text(
                'INICI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              Text(
                '$current DE $target CIMS',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              const Text(
                'OBJECTIU',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
