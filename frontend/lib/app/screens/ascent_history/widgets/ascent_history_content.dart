import 'package:cims/app/screens/ascent_history/widgets/ascent_history_empty_state.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_error_state.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_header.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_timeline.dart';
import 'package:cims/app/widgets/ascent_verified_badge.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa el contingut principal de la pantalla d’historial.
// Decideix si cal mostrar càrrega, error, estat buit, línia temporal o registres sense data.
class AscentHistoryContent extends StatelessWidget {
  const AscentHistoryContent({
    super.key,
    required this.peakName,
    required this.altitude,
    required this.regions,
    required this.ascents,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onRetryTap,
    required this.onAscentTap,
  });

  final String peakName;
  final int altitude;
  final List<String> regions;
  final List<Ascent> ascents;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryTap;
  final ValueChanged<Ascent> onAscentTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final datedAscents =
        ascents.where((ascent) => ascent.ascentDate != null).toList();

    final undatedAscents =
        ascents.where((ascent) => ascent.ascentDate == null).toList();

    final hasAnyAscents = datedAscents.isNotEmpty || undatedAscents.isNotEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          AscentHistoryHeader(
            peakName: peakName,
            altitude: altitude,
            regions: regions,
            totalAscents: datedAscents.length,
          ),
          const SizedBox(height: 30),
          if (errorMessage != null)
            AscentHistoryErrorState(
              message: errorMessage!,
              onRetryTap: onRetryTap,
            )
          else if (!hasAnyAscents)
            const AscentHistoryEmptyState()
          else ...[
            if (datedAscents.isNotEmpty)
              AscentHistoryTimeline(
                ascents: datedAscents,
                onAscentTap: onAscentTap,
              ),
            if (datedAscents.isNotEmpty && undatedAscents.isNotEmpty)
              const SizedBox(height: 28),
            if (undatedAscents.isNotEmpty)
              _UndatedAscentsSection(
                ascents: undatedAscents,
                onAscentTap: onAscentTap,
              ),
          ],
        ],
      ),
    );
  }
}

// Aquest bloc mostra les ascensions que no tenen data.
// Es manté separat de la cronologia perquè l’usuari les pugui revisar o completar.
class _UndatedAscentsSection extends StatelessWidget {
  const _UndatedAscentsSection({
    required this.ascents,
    required this.onAscentTap,
  });

  final List<Ascent> ascents;
  final ValueChanged<Ascent> onAscentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registres sense data',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF252525),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aquests registres completen el cim, però no apareixen a la cronologia.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 14),
        for (final ascent in ascents) ...[
          _UndatedAscentCard(
            ascent: ascent,
            onTap: () => onAscentTap(ascent),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// Aquesta targeta permet accedir a l’edició d’un registre sense data.
// També mostra si l’ascensió ja ha estat verificada per geolocalització.
class _UndatedAscentCard extends StatelessWidget {
  const _UndatedAscentCard({
    required this.ascent,
    required this.onTap,
  });

  final Ascent ascent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 20,
                  color: Color(0xFF0B57D0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ascent.hasNotes
                          ? ascent.notes!
                          : 'Ascensió registrada sense data',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF344054),
                      ),
                    ),
                    if (ascent.isVerified) ...[
                      const SizedBox(height: 8),
                      const AscentVerifiedBadge(
                        label: 'Verificada',
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
