import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra el cim seleccionat al mapa.
// Dona context a l’usuari i permet obrir directament el detall del cim.
class PeaksMapSelectedPeakCard extends StatelessWidget {
  const PeaksMapSelectedPeakCard({
    super.key,
    required this.peak,
    required this.onDetailTap,
  });

  // Aquest bloc rep el cim seleccionat i l’acció per obrir-ne el detall.
  // Això permet que la targeta mostri informació del cim sense gestionar la navegació.
  final Peak peak;
  final VoidCallback onDetailTap;

  // Construeix la targeta resum del cim seleccionat.
  // Mostra el nom, l’altitud, les comarques associades i l’accés al detall complet.
  @override
  Widget build(BuildContext context) {
    final regionsText = peak.formattedRegions.isEmpty
        ? 'Sense comarca informada'
        : peak.formattedRegions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            peak.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17212B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${peak.altitude} m · $regionsText',
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5B6573),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDetailTap,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Veure detall del cim'),
            ),
          ),
        ],
      ),
    );
  }
}