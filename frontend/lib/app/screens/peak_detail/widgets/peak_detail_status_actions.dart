import 'package:flutter/material.dart';

// Aquest widget mostra la zona reservada per a l’estat personal del cim.
// La lògica real arribarà quan backend integri PeakStatus.
class PeakDetailStatusActions extends StatelessWidget {
  const PeakDetailStatusActions({
    super.key,
    this.isTarget = false,
    this.isCompleted = false,
    this.isFavorite = false,
    this.areActionsEnabled = false,
    this.onTargetTap,
    this.onCompletedTap,
    this.onFavoriteTap,
  });

  // Aquest bloc rep l’estat actual del cim i les accions disponibles
  // per poder reflectir visualment si el cim està marcat com a objectiu,
  // completat o preferit.
  final bool isTarget;
  final bool isCompleted;
  final bool isFavorite;
  final bool areActionsEnabled;
  final VoidCallback? onTargetTap;
  final VoidCallback? onCompletedTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    // Aquest bloc construeix la secció d’estat del cim dins la pantalla de detall.
    // Mostra les tres accions principals i, si encara no estan actives,
    // informa clarament que aquesta part queda pendent d’integració.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estat del cim',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17212B),
          ),
        ),
        const SizedBox(height: 14),
        _PeakStatusButton(
          label: 'Objectiu',
          icon: Icons.flag_rounded,
          isActive: isTarget,
          color: const Color(0xFF0E63F4),
          onTap: areActionsEnabled ? onTargetTap : null,
        ),
        const SizedBox(height: 12),
        _PeakStatusButton(
          label: 'Completat',
          icon: Icons.check_circle_rounded,
          isActive: isCompleted,
          color: const Color(0xFF18B56A),
          onTap: areActionsEnabled ? onCompletedTap : null,
        ),
        const SizedBox(height: 12),
        _PeakStatusButton(
          label: 'Preferit',
          icon: Icons.favorite_rounded,
          isActive: isFavorite,
          color: const Color(0xFFE84A4A),
          onTap: areActionsEnabled ? onFavoriteTap : null,
        ),
        if (!areActionsEnabled) ...[
          const SizedBox(height: 12),
          const Text(
            'Aquesta part quedarà connectada quan backend integri PeakStatus.', //TODO: Reemplaçar aquest missatge quan es conegui el motiu de la falta d’integració (ex. funcionalitat pendent, dependència externa, etc.).
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

// Aquest botó intern construeix una única acció visual
// amb un estil consistent per a l’estat del cim.
class _PeakStatusButton extends StatelessWidget {
  const _PeakStatusButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  // Aquestes propietats defineixen com es veu i com es comporta
  // cadascuna de les opcions d’estat dins del detall del cim.
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    // Aquest bloc adapta l’aspecte del botó segons el seu estat actual:
    // actiu, disponible per interactuar o encara desactivat.
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
            horizontal: 18,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: foregroundColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
              Icon(
                isActive
                    ? Icons.check_rounded
                    : Icons.chevron_right_rounded,
                color: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}