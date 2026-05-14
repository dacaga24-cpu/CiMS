import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra les etiquetes d’estat d’un cim.
// Permet veure ràpidament si està completat, verificat, marcat com a objectiu o preferit.
class PeakStatusTags extends StatelessWidget {
  const PeakStatusTags({
    super.key,
    required this.status,
  });

  final PeakStatus? status;

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
        if (currentStatus.hasVerifiedAscent)
          const _PeakStatusTag(
            label: 'Verificat',
            icon: Icons.location_on_rounded,
            color: Color(0xFF7C3AED),
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

// Aquesta etiqueta representa un estat concret del cim.
// Combina color, icona i text per mantenir una lectura visual clara al catàleg.
class _PeakStatusTag extends StatelessWidget {
  const _PeakStatusTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

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