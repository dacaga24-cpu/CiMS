import 'package:cims/app/widgets/ascent_verified_badge.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
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

  @override
  Widget build(BuildContext context) {
    final datedAscents =
        ascents.where((ascent) => ascent.ascentDate != null).toList();

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

// Aquest widget representa una ascensió dins la línia temporal.
// Mostra la data, la foto principal, les notes i l’estat de verificació.
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
    final primaryPhoto = ascent.primaryPhoto;
    final photoUrl = primaryPhoto?.downloadUrl;

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
                      if (photoUrl != null) ...[
                        const SizedBox(height: 10),
                        _AscentPhotoPreview(
                          photoUrl: photoUrl,
                          isEvidence:
                              primaryPhoto?.isVerificationEvidence ?? false,
                        ),
                      ],
                      const SizedBox(height: 8),
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

// Aquest widget mostra una vista prèvia de la foto principal de l’ascensió.
// Si la imatge és l’evidència de verificació, ho indica amb una etiqueta visual.
class _AscentPhotoPreview extends StatelessWidget {
  const _AscentPhotoPreview({
    required this.photoUrl,
    required this.isEvidence,
  });

  final String photoUrl;
  final bool isEvidence;

  @override
  Widget build(BuildContext context) {
    // A mòbil deixem que la imatge ocupi tota l'amplada disponible perquè
    // el contingut ja és prou estret. A tablet/desktop, en canvi, una foto
    // que ocupa tot el card crida massa l'atenció, així que la limitem
    // perquè quedi proporcionada respecte al text.
    final isCompact = AppResponsive.isCompact(context);
    final maxWidth = isCompact ? double.infinity : 360.0;

    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF2F4F7),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: Color(0xFF98A2B3),
                  ),
                );
              },
            ),
            if (isEvidence)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Evidència',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // A mòbil la imatge ja ocupa tota l'amplada del card pare; evitem
    // afegir capes extra de `Align` + `ConstrainedBox` que no aportarien
    // res visualment.
    if (isCompact) return preview;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: preview,
      ),
    );
  }
}
