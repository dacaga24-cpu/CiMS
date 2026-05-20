import 'package:flutter/material.dart';

// Aquest widget mostra les accions manuals disponibles al detall del cim.
// L’estat completat ja es mostra a la capçalera, perquè depèn de les ascensions registrades.
class PeakDetailStatusActions extends StatelessWidget {
  const PeakDetailStatusActions({
    super.key,
    this.isTarget = false,
    this.isFavorite = false,
    this.areActionsEnabled = false,
    this.onTargetTap,
    this.onFavoriteTap,
  });

  final bool isTarget;
  final bool isFavorite;
  final bool areActionsEnabled;
  final VoidCallback? onTargetTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _PeakStatusButton(
                label: 'Objectiu',
                icon: Icons.flag_rounded,
                isActive: isTarget,
                color: const Color(0xFFF97316),
                onTap: areActionsEnabled ? onTargetTap : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PeakStatusButton(
                label: 'Preferit',
                icon: Icons.favorite_rounded,
                isActive: isFavorite,
                color: const Color(0xFFE84A4A),
                onTap: areActionsEnabled ? onFavoriteTap : null,
              ),
            ),
          ],
        ),
        if (!areActionsEnabled) ...[
          const SizedBox(height: 12),
          const Text(
            'Actualitzant l’estat del cim...',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ],
    );
  }
}

// Aquest botó intern representa una acció manual sobre el cim.
// Actualment s’utilitza per marcar-lo com a objectiu o preferit.
class _PeakStatusButton extends StatelessWidget {
  const _PeakStatusButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    final backgroundColor = isActive
        ? color
        : isEnabled
            ? color.withValues(alpha: 0.12)
            : const Color(0xFFF2F4F7);

    final foregroundColor = isActive
        ? Colors.white
        : isEnabled
            ? color
            : const Color(0xFF98A2B3);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: foregroundColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
              Icon(
                isActive ? Icons.check_rounded : Icons.chevron_right_rounded,
                color: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
