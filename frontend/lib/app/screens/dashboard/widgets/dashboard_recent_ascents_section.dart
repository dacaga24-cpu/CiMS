import 'package:cims/app/widgets/peaks/peak_circular_thumbnail.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/util/format.dart';
import 'package:flutter/material.dart';

// Aquesta secció mostra les últimes ascensions dins del dashboard.
// Representa activitat recent de cims completats i permet accedir
// al catàleg filtrat per veure tots els cims completats.
class DashboardRecentAscentsSection extends StatelessWidget {
  const DashboardRecentAscentsSection({
    super.key,
    required this.ascents,
    required this.onAscentTap,
    this.onViewAllTap,
  });

  // Aquestes dades defineixen les ascensions recents i les accions disponibles.
  // L'acció de veure tots porta al catàleg amb el filtre de cims completats.
  final List<DashboardRecentAscent> ascents;
  final ValueChanged<DashboardRecentAscent> onAscentTap;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xFF18B56A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Últimes ascensions',
                  style: TextStyle(
                    color: Color(0xFF1F2933),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onViewAllTap != null)
                TextButton(
                  onPressed: onViewAllTap,
                  style: TextButton.styleFrom(
                    foregroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Veure tots',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (ascents.isEmpty)
            const Text(
              'Encara no tens ascensions recents.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            for (var index = 0; index < ascents.length; index++) ...[
              _DashboardRecentAscentTile(
                ascent: ascents[index],
                onTap: () => onAscentTap(ascents[index]),
              ),
              if (index != ascents.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

// Aquest element representa una ascensió recent dins del dashboard.
// Mostra la miniatura del cim, el nom, la zona, l'altitud i la data.
class _DashboardRecentAscentTile extends StatelessWidget {
  const _DashboardRecentAscentTile({
    required this.ascent,
    required this.onTap,
  });

  final DashboardRecentAscent ascent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle(ascent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            const PeakCircularThumbnail(
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ascent.peakName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(ascent.ascentDate),
                  style: const TextStyle(
                    color: Color(0xFF1F2933),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(DashboardRecentAscent ascent) {
    final parts = <String>[
      if (ascent.regionName != null && ascent.regionName!.trim().isNotEmpty)
        ascent.regionName!,
      if (ascent.altitude != null) formatAltitude(ascent.altitude),
    ];

    return parts.join(' · ');
  }

  String _formatDate(String value) {
    final parsedDate = DateTime.tryParse(value);

    if (parsedDate == null) {
      return value;
    }

    const months = [
      'Gen',
      'Feb',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Oct',
      'Nov',
      'Des',
    ];

    final day = parsedDate.day.toString().padLeft(2, '0');
    final month = months[parsedDate.month - 1];

    return '$day $month';
  }
}
