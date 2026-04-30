import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra el cim seleccionat dins del mateix mapa.
// Manté el context de la selecció i ofereix un accés directe al detall.
class PeaksMapSelectedPeakCard extends StatelessWidget {
  const PeaksMapSelectedPeakCard({
    super.key,
    required this.peak,
    required this.onDetailTap,
  });

  // Aquest bloc rep el cim seleccionat i l’acció per obrir-ne el detall.
  final Peak peak;
  final VoidCallback onDetailTap;

  // Construeix una targeta compacta amb la informació principal i el botó d’acció.
  @override
  Widget build(BuildContext context) {
    final regionsText = peak.formattedRegions.isEmpty
        ? 'Sense comarca informada'
        : peak.formattedRegions;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            peak.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17212B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${peak.altitude} m · $regionsText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5B6573),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 118,
              child: PrimaryGradientButton(
                label: 'Detall',
                icon: Icons.open_in_new_rounded,
                height: 38,
                fontSize: 15,
                iconSize: 16,
                onPressed: onDetailTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
