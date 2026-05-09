import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/peaks/peak_circular_thumbnail.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra el cim seleccionat dins del mateix mapa.
// Manté el context de la selecció, mostra l’estat personal del cim
// i ofereix un accés directe al detall.
class PeaksMapSelectedPeakCard extends StatelessWidget {
  const PeaksMapSelectedPeakCard({
    super.key,
    required this.peak,
    required this.onDetailTap,
    this.status,
    this.onTargetTap,
    this.onFavoriteTap,
  });

  // Aquest bloc rep el cim seleccionat, el seu estat personal opcional
  // i les accions disponibles des de la targeta ràpida del mapa.
  final Peak peak;
  final VoidCallback onDetailTap;
  final PeakStatus? status;
  final VoidCallback? onTargetTap;
  final VoidCallback? onFavoriteTap;

  // Construeix una targeta compacta amb imatge, informació principal,
  // estat completat i accions manuals d’objectiu i preferit.
  @override
  Widget build(BuildContext context) {
    final regionsText = peak.formattedRegions.isEmpty
        ? 'Sense comarca informada'
        : peak.formattedRegions;

    final currentStatus = status ?? PeakStatus.emptyForPeak(peak.id);

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PeakCircularThumbnail(
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B6573),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CompletedMiniSeal(
                      isCompleted: currentStatus.isCompleted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MapStatusButton(
                  label: 'Objectiu',
                  icon: Icons.flag_rounded,
                  isActive: currentStatus.isTarget,
                  color: const Color(0xFFF97316),
                  onTap: onTargetTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MapStatusButton(
                  label: 'Preferit',
                  icon: Icons.favorite_rounded,
                  isActive: currentStatus.isFavorite,
                  color: const Color(0xFFE84A4A),
                  onTap: onFavoriteTap,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: PrimaryGradientButton(
                  label: 'Detall',
                  height: 38,
                  fontSize: 14,
                  iconSize: 15,
                  onPressed: onDetailTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Aquest segell indica si el cim està completat.
// No és interactiu perquè el completat deriva de les ascensions registrades.
class _CompletedMiniSeal extends StatelessWidget {
  const _CompletedMiniSeal({
    required this.isCompleted,
  });

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? const Color(0xFF18B56A)
        : const Color(0xFF98A2B3);

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
            isCompleted
                ? Icons.verified_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isCompleted ? 'Completat' : 'No completat',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest botó representa una acció manual ràpida dins del mapa.
// Només s’utilitza per objectiu i preferit.
class _MapStatusButton extends StatelessWidget {
  const _MapStatusButton({
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: foregroundColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}