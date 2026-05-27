import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/user_stats/user_stats_controller.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_challenge_card.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_error_state.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_history_card.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_loading_state.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_most_ascended_card.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_range_selector.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_total_meters_card.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:cims/core/entity/user_stats.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra les estadístiques personals de l’usuari.
// Permet consultar el progrés, refrescar les dades i obrir el detall d’un cim.
@RoutePage()
class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

// Aquest estat connecta la pantalla amb el controller d’estadístiques.
// També resol la navegació cap al detall dels cims seleccionats.
class _UserStatsScreenState extends State<UserStatsScreen> {
  late final UserStatsController controller;

  @override
  void initState() {
    super.initState();
    controller = UserStatsController();
    controller.initialize();
  }

  // Aquest mètode allibera el controller quan la pantalla es tanca.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla segons l’estat de càrrega.
  // Mostra càrrega inicial, error o el contingut estadístic quan hi ha dades disponibles.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final stats = controller.stats;

        if (controller.isInitialLoading) {
          return const StatsLoadingState();
        }

        if (stats == null) {
          return StatsErrorState(
            message: controller.errorMessage ??
                'No hi ha dades d\'estadístiques disponibles',
            onRetryTap: controller.onRetryTap,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppResponsive.pagePadding(
              context,
              compactHorizontal: 16,
              compactTop: 0,
              compactBottom: 24,
            ),
            children: [
              ResponsiveConstrainedBox(
                child: _UserStatsContent(
                  stats: stats,
                  controller: controller,
                  onPeakTap: _openPeakDetail,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Aquest mètode obre el detall del cim seleccionat.
  // Es reutilitza des de les targetes que mostren cims dins de les estadístiques.
  void _openPeakDetail(int peakId) {
    context.router.root.push(PeakDetailRoute(peakId: peakId));
  }
}

// Aquest widget agrupa el contingut principal de les estadístiques.
// Adapta la distribució segons la mida de pantalla.
class _UserStatsContent extends StatelessWidget {
  const _UserStatsContent({
    required this.stats,
    required this.controller,
    required this.onPeakTap,
  });

  // Aquestes dades permeten pintar les mètriques i executar accions del controller.
  final UserStats stats;
  final UserStatsController controller;
  final ValueChanged<int> onPeakTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppResponsive.isCompact(context);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _withVerticalGaps(
          [
            const _StatsHeader(),
            StatsMostAscendedCard(
              topAscendedPeaks: stats.topAscendedPeaks,
              onPeakTap: onPeakTap,
            ),
            _StatsMonthlyStreakCard(
              current: stats.monthlyStreak.current,
              best: stats.monthlyStreak.best,
            ),
            StatsHistoryCard(
              totalAscents: stats.totalAscents,
              monthlyAscents: stats.monthlyAscents,
              monthsToShow: 12,
            ),
            StatsChallengeCard(
              current: controller.challengeCurrent,
              target: controller.challengeTarget,
              percentage: controller.challengePercentage,
            ),
            StatsRangeSelector(
              options: controller.rangeOptions,
              selectedRange: controller.selectedRange,
              onRangeSelected: controller.onRangeChanged,
            ),
            StatsTotalMetersCard(
              totalMeters: stats.totalAltitudeMeters,
              comparisonLabel: controller.monthlyComparisonLabel,
            ),
          ],
          firstGap: 28,
          gap: 14,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;

        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _withVerticalGaps(
              [
                const _StatsHeader(),
                StatsMostAscendedCard(
                  topAscendedPeaks: stats.topAscendedPeaks,
                  onPeakTap: onPeakTap,
                ),
                _StatsMonthlyStreakCard(
                  current: stats.monthlyStreak.current,
                  best: stats.monthlyStreak.best,
                ),
                StatsHistoryCard(
                  totalAscents: stats.totalAscents,
                  monthlyAscents: stats.monthlyAscents,
                  monthsToShow: 12,
                ),
                StatsChallengeCard(
                  current: controller.challengeCurrent,
                  target: controller.challengeTarget,
                  percentage: controller.challengePercentage,
                ),
                StatsRangeSelector(
                  options: controller.rangeOptions,
                  selectedRange: controller.selectedRange,
                  onRangeSelected: controller.onRangeChanged,
                ),
                StatsTotalMetersCard(
                  totalMeters: stats.totalAltitudeMeters,
                  comparisonLabel: controller.monthlyComparisonLabel,
                ),
              ],
              firstGap: 24,
              gap: 16,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StatsHeader(),
            const SizedBox(height: 24),
            SizedBox(
              width: 620,
              child: StatsRangeSelector(
                options: controller.rangeOptions,
                selectedRange: controller.selectedRange,
                onRangeSelected: controller.onRangeChanged,
              ),
            ),
            const SizedBox(height: 18),
            // Aquesta fila iguala l’alçada de les dues targetes superiors.
            // Manté una composició visual equilibrada en pantalles amples.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatsMostAscendedCard(
                      topAscendedPeaks: stats.topAscendedPeaks,
                      onPeakTap: onPeakTap,
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _StatsMonthlyStreakCard(
                      current: stats.monthlyStreak.current,
                      best: stats.monthlyStreak.best,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StatsHistoryCard(
              totalAscents: stats.totalAscents,
              monthlyAscents: stats.monthlyAscents,
              monthsToShow: 12,
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatsChallengeCard(
                      current: controller.challengeCurrent,
                      target: controller.challengeTarget,
                      percentage: controller.challengePercentage,
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: StatsTotalMetersCard(
                      totalMeters: stats.totalAltitudeMeters,
                      comparisonLabel: controller.monthlyComparisonLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Aquest mètode afegeix separació vertical entre blocs.
  // Permet reutilitzar la mateixa composició en formats compactes i mitjans.
  List<Widget> _withVerticalGaps(
    List<Widget> children, {
    required double firstGap,
    required double gap,
  }) {
    final spaced = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      if (index == 1) {
        spaced.add(SizedBox(height: firstGap));
      } else if (index > 1) {
        spaced.add(SizedBox(height: gap));
      }

      spaced.add(children[index]);
    }

    return spaced;
  }
}

// Aquesta capçalera identifica la pantalla d’estadístiques.
// Dona context sobre el tipus de progrés que es mostra.
class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadístiques',
          style: TextStyle(
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141414),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'El teu progrés als cims de Catalunya',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5E6572),
          ),
        ),
      ],
    );
  }
}

// Aquesta targeta mostra la ratxa mensual d’ascensions.
// Compara la ratxa actual amb la millor ratxa registrada.
class _StatsMonthlyStreakCard extends StatelessWidget {
  const _StatsMonthlyStreakCard({
    required this.current,
    required this.best,
  });

  // Aquests valors representen la ratxa actual i la millor ratxa històrica.
  final int current;
  final int best;

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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFF97316),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RATXA MENSUAL',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF97316),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  current == 1
                      ? '1 mes seguit amb ascensions'
                      : '$current mesos seguits amb ascensions',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF181818),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  best == 1
                      ? 'Millor ratxa: 1 mes'
                      : 'Millor ratxa: $best mesos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
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