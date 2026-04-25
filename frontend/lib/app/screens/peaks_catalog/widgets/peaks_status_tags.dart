import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra els indicadors visuals dels estats personals d’un cim.
// Només mostra els estats actius per evitar carregar visualment el catàleg
// amb etiquetes innecessàries.
class PeakStatusTags extends StatelessWidget {
  const PeakStatusTags({
    super.key,
    required this.status,
  });

  // Aquesta propietat rep l’estat personal del cim.
  // Si no hi ha cap estat actiu, el widget no mostra cap etiqueta.
  final PeakStatus? status;

  // Aquest mètode construeix el conjunt d’etiquetes visibles segons l’estat del cim.
  // Permet identificar ràpidament si el cim està completat, marcat com a objectiu o preferit.
  @override
  Widget build(BuildContext context) {
    final currentStatus = status;

    if (currentStatus == null || !currentStatus.hasAnyStatus) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (currentStatus.isCompleted)
          const _PeakStatusTag(
            label: 'Completat',
            icon: Icons.check_circle_rounded,
            color: Color(0xFF18B56A),
          ),
        if (currentStatus.isTarget)
          const _PeakStatusTag(
            label: 'Objectiu',
            icon: Icons.flag_rounded,
            color: Color(0xFFF97316),
          ),
        if (currentStatus.isFavorite)
          const _PeakStatusTag(
            label: 'Preferit',
            icon: Icons.favorite_rounded,
            color: Color(0xFFE84A4A),
          ),
      ],
    );
  }
}

// Aquest widget intern representa una etiqueta individual.
// Combina icona, text i color per fer l’estat fàcil d’identificar.
class _PeakStatusTag extends StatelessWidget {
  const _PeakStatusTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  // Aquestes propietats defineixen el contingut visual de cada etiqueta
  // segons el tipus d’estat que representa.
  final String label;
  final IconData icon;
  final Color color;

  // Aquest mètode construeix una etiqueta compacta d’estat.
  // Es fa servir dins de les targetes del catàleg per resumir informació sense ocupar massa espai.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}