import 'package:cims/app/widgets/ascent_verified_badge.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget construeix la capçalera principal del detall del cim.
// Mostra la informació destacada del cim i els indicadors de completat
// i verificació quan l’usuari ja té progrés registrat.
class PeakDetailHeader extends StatelessWidget {
  const PeakDetailHeader({
    super.key,
    required this.peak,
    this.lastAscentDate,
    this.isCompleted = false,
    this.hasVerifiedAscent = false,
  });

  final Peak peak;
  final DateTime? lastAscentDate;
  final bool isCompleted;
  final bool hasVerifiedAscent;

  @override
  Widget build(BuildContext context) {
    final regionsText =
        peak.formattedRegions.isEmpty ? 'CATALUNYA' : peak.formattedRegions;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/montana_0001.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
        ),
        child: Stack(
          children: [
            if (isCompleted || hasVerifiedAscent)
              Positioned(
                top: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isCompleted)
                      const _CompletedHeaderBadge(),
                    if (isCompleted && hasVerifiedAscent)
                      const SizedBox(height: 8),
                    if (hasVerifiedAscent)
                      const AscentVerifiedBadge(
                        label: 'Asc. verificada',
                        compact: true,
                      ),
                  ],
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastAscentDate != null) ...[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Últim ascens: ${_formatDate(lastAscentDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF24465D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: const BoxDecoration(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Aquest bloc mostra la ubicació general i les dades principals del cim.
                // El fons clar garanteix que el text sigui llegible damunt la imatge.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        regionsText.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Color(0xFF24465D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        peak.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${peak.altitude} metres',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

// Aquest badge indica que el cim ja està completat.
// Es mostra dins la imatge principal per donar visibilitat immediata a l’estat del cim.
class _CompletedHeaderBadge extends StatelessWidget {
  const _CompletedHeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF18B56A),
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
            Icons.check_rounded,
            size: 13,
            color: Colors.white,
          ),
          SizedBox(width: 5),
          Text(
            'Cim completat',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}