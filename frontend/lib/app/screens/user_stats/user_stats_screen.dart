import 'package:auto_route/auto_route.dart';
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

@RoutePage()
class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

class _UserStatsScreenState extends State<UserStatsScreen> {
  late final UserStatsController controller;

  @override
  void initState() {
    super.initState();
    controller = UserStatsController();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserStatsContent extends StatelessWidget {
  const _UserStatsContent({
    required this.stats,
    required this.controller,
  });

  final UserStats stats;
  final UserStatsController controller;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppResponsive.isCompact(context);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _withVerticalGaps(
          [
            const _StatsHeader(),
            StatsMostAscendedCard(topAscendedPeaks: stats.topAscendedPeaks),
            StatsChallengeCard(
              current: controller.challengeCurrent,
              target: controller.challengeTarget,
              percentage: controller.challengePercentage,
            ),
            StatsHistoryCard(
              totalAscents: stats.totalAscents,
              monthlyAscents: stats.monthlyAscents,
              monthsToShow: 12,
            ),
            _StatsMonthlyStreakCard(
              current: stats.monthlyStreak.current,
              best: stats.monthlyStreak.best,
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
                StatsMostAscendedCard(topAscendedPeaks: stats.topAscendedPeaks),
                StatsChallengeCard(
                  current: controller.challengeCurrent,
                  target: controller.challengeTarget,
                  percentage: controller.challengePercentage,
                ),
                StatsHistoryCard(
                  totalAscents: stats.totalAscents,
                  monthlyAscents: stats.monthlyAscents,
                  monthsToShow: 12,
                ),
                _StatsMonthlyStreakCard(
                  current: stats.monthlyStreak.current,
                  best: stats.monthlyStreak.best,
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

        final cardWidth = (constraints.maxWidth - spacing) / 2;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatsMostAscendedCard(
                    topAscendedPeaks: stats.topAscendedPeaks,
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: StatsChallengeCard(
                    current: controller.challengeCurrent,
                    target: controller.challengeTarget,
                    percentage: controller.challengePercentage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            StatsHistoryCard(
              totalAscents: stats.totalAscents,
              monthlyAscents: stats.monthlyAscents,
              monthsToShow: 12,
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _StatsMonthlyStreakCard(
                    current: stats.monthlyStreak.current,
                    best: stats.monthlyStreak.best,
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: StatsTotalMetersCard(
                    totalMeters: stats.totalAltitudeMeters,
                    comparisonLabel: controller.monthlyComparisonLabel,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

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

class _StatsMonthlyStreakCard extends StatelessWidget {
  const _StatsMonthlyStreakCard({
    required this.current,
    required this.best,
  });

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
