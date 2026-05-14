import 'package:cims/app/widgets/ascent_verified_badge.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:flutter/material.dart';

// Aquest widget representa les ascensions del cim en format de línia temporal.
// Ajuda a visualitzar l’historial personal mantenint només els registres amb data.
class AscentHistoryTimeline extends StatelessWidget {
  const AscentHistoryTimeline({
    super.key,
    required this.ascents,
    required this.onAscentTap,
  });

  final List<Ascent> ascents;
  final ValueChanged<Ascent> onAscentTap;

  // Aquest mètode construeix la línia vertical i els punts associats a cada ascensió.
  // Els registres sense data es mostren en una secció separada de l’historial.
  @override
  Widget build(BuildContext context) {
    final datedAscents = ascents
        .where((ascent) => ascent.ascentDate != null)
        .toList();

    return Column(
      children: [
        for (var index = 0; index < datedAscents.length; index++)
          _TimelineItem(
            ascent: datedAscents[index],
            isFirst: index == 0,
            isLast: index == datedAscents.length - 1,
            onTap: () => onAscentTap(datedAscents[index]),
          ),
      ],
    );
  }
}

// Aquest widget representa una ascensió individual dins de la línia temporal.
// Mostra la data, les notes i l’etiqueta de verificació quan l’ascensió ha estat validada.
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.ascent,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Ascent ascent;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ascentDate = ascent.ascentDate;

    if (ascentDate == null) {
      return const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 18,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: const Color(0xFF0E63F4),
                    ),
                  ),
                if (!isFirst)
                  Positioned(
                    top: 0,
                    height: 9,
                    child: Container(
                      width: 2,
                      color: const Color(0xFF0E63F4),
                    ),
                  ),
                Positioned(
                  top: 9,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0E63F4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: isLast ? 0 : 26,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'Ascensió registrada',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF252525),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(ascentDate),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5E6572),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF98A2B3),
                          ),
                        ],
                      ),
                      if (ascent.isVerified) ...[
                        const SizedBox(height: 7),
                        const AscentVerifiedBadge(
                          label: 'Verificada',
                          compact: true,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        ascent.hasNotes
                            ? ascent.notes!
                            : 'Sense notes registrades.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6E7480),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'gen',
      'feb',
      'març',
      'abr',
      'maig',
      'juny',
      'jul',
      'ag',
      'set',
      'oct',
      'nov',
      'des',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();

    return '$day $month $year';
  }
}