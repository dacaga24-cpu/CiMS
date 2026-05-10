import 'package:cims/app/widgets/peaks/peak_circular_thumbnail.dart';
import 'package:cims/core/entity/user_stats.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra els tres cims que l’usuari ha coronat més vegades.
// Si encara no hi ha dades suficients, mostra un estat neutre.
class StatsMostAscendedCard extends StatelessWidget {
  const StatsMostAscendedCard({
    super.key,
    required this.topAscendedPeaks,
  });

  // Aquesta llista conté els cims amb més ascensions registrades.
  // El backend ja els retorna ordenats de més a menys repeticions.
  final List<MostAscendedPeakStats> topAscendedPeaks;

  // Aquest mètode construeix la targeta del top 3 de cims més coronats.
  // Mostra el rànquing quan hi ha dades i un missatge orientatiu quan encara no n’hi ha.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOP 3 CIMS MÉS CORONATS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F5ADB),
            ),
          ),
          const SizedBox(height: 14),
          if (topAscendedPeaks.isEmpty)
            const _EmptyTopAscendedState()
          else
            for (var index = 0; index < topAscendedPeaks.length; index++) ...[
              _TopAscendedPeakRow(
                position: index + 1,
                peak: topAscendedPeaks[index],
              ),
              if (index != topAscendedPeaks.length - 1)
                const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

// Aquest element representa un cim dins del rànquing.
// Mostra la posició, la miniatura, el nom, les comarques, l’altitud i el nombre d’ascensions.
class _TopAscendedPeakRow extends StatelessWidget {
  const _TopAscendedPeakRow({
    required this.position,
    required this.peak,
  });

  final int position;
  final MostAscendedPeakStats peak;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (peak.formattedRegions.isNotEmpty) peak.formattedRegions,
      if (peak.peakAltitude != null) '${_formatNumber(peak.peakAltitude!)} m',
    ];

    return Row(
      children: [
        _RankingBadge(position: position),
        const SizedBox(width: 10),
        const PeakCircularThumbnail(
          size: 48,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                peak.peakName.isEmpty ? 'Cim sense nom' : peak.peakName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF181818),
                ),
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitleParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        _AscentsCounter(totalAscents: peak.totalAscents),
      ],
    );
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

// Aquest indicador mostra la posició del cim dins del top.
// Ajuda a llegir el rànquing de manera ràpida.
class _RankingBadge extends StatelessWidget {
  const _RankingBadge({
    required this.position,
  });

  final int position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF1FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$position',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F5ADB),
          ),
        ),
      ),
    );
  }
}

// Aquest bloc mostra el nombre d’ascensions registrades per al cim.
// Manté el recompte separat de la informació descriptiva del cim.
class _AscentsCounter extends StatelessWidget {
  const _AscentsCounter({
    required this.totalAscents,
  });

  final int totalAscents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$totalAscents',
          style: const TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F5ADB),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          totalAscents == 1 ? 'cop' : 'cops',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// Aquest estat s’utilitza quan encara no hi ha ascensions suficients.
// Dona una explicació clara sense deixar la targeta buida.
class _EmptyTopAscendedState extends StatelessWidget {
  const _EmptyTopAscendedState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        PeakCircularThumbnail(
          size: 48,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Registra ascensions per veure els teus cims més coronats.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}