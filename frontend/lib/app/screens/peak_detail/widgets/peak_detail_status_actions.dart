import 'package:flutter/material.dart';

// Aquest widget mostra l’estat personal del cim dins del detall.
// L’estat completat es presenta com un segell informatiu, perquè ja no es pot
// modificar manualment: només deriva de les ascensions registrades.
class PeakDetailStatusActions extends StatelessWidget {
  const PeakDetailStatusActions({
    super.key,
    this.isTarget = false,
    this.isCompleted = false,
    this.isFavorite = false,
    this.areActionsEnabled = false,
    this.onTargetTap,
    this.onFavoriteTap,
  });

  // Aquest bloc rep l’estat actual del cim i les accions manuals disponibles.
  // Només objectiu i preferit es poden modificar des d’aquesta pantalla.
  // Completat queda com a informació derivada del registre d’ascensions.
  final bool isTarget;
  final bool isCompleted;
  final bool isFavorite;
  final bool areActionsEnabled;
  final VoidCallback? onTargetTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    // Aquest bloc construeix la secció d’estat del cim dins la pantalla de detall.
    // Separa el segell de completat de les accions manuals per evitar confusió.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        _CompletedStatusSeal(
          isCompleted: isCompleted,
        ),
        const SizedBox(height: 12),
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

        // Aquest missatge informa l’usuari que les accions manuals estan
        // temporalment bloquejades mentre es carrega o s’actualitza l’estat.
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

// Aquest segell mostra si el cim està completat.
// No és interactiu perquè el completat depèn dels registres d’ascensió.
class _CompletedStatusSeal extends StatelessWidget {
  const _CompletedStatusSeal({
    required this.isCompleted,
  });

  // Indica si el cim té almenys una ascensió registrada per l’usuari.
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCompleted
        ? const Color(0xFF18B56A).withValues(alpha: 0.12)
        : const Color(0xFFF2F4F7);

    final foregroundColor = isCompleted
        ? const Color(0xFF12814C)
        : const Color(0xFF667085);

    final icon = isCompleted
        ? Icons.verified_rounded
        : Icons.radio_button_unchecked_rounded;

    final title = isCompleted ? 'Cim completat' : 'Cim no completat';

    final subtitle = isCompleted
        ? 'Aquest cim té almenys una ascensió registrada.'
        : 'Per completar-lo, registra una ascensió.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor.withValues(alpha: 0.82),
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

// Aquest botó intern construeix una acció manual de l’estat del cim.
// Només s’utilitza per objectiu i preferit.
class _PeakStatusButton extends StatelessWidget {
  const _PeakStatusButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  // Aquestes propietats defineixen com es veu i com es comporta
  // cadascuna de les opcions manuals dins del detall del cim.
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    // Aquest bloc adapta l’aspecte del botó segons el seu estat actual:
    // actiu, disponible per interactuar o temporalment desactivat.
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