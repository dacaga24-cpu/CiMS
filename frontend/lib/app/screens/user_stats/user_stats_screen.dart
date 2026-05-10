import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/user_stats/user_stats_controller.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_challenge_card.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_error_state.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_history_card.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_loading_state.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_most_ascended_card.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_range_selector.dart';
import 'package:cims/app/screens/user_stats/widgets/stats_total_meters_card.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el resum d’estadístiques de l’usuari.
// Forma part de la navegació principal i utilitza el controller per carregar
// les dades reals del backend sense barrejar lògica de dades amb la UI.
@RoutePage()
class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

// Aquesta classe prepara el controller i construeix el contingut visual
// segons l’estat actual: càrrega, error o estadístiques carregades.
class _UserStatsScreenState extends State<UserStatsScreen> {
  late final UserStatsController controller;

  // Aquest mètode inicialitza el controller quan la pantalla entra en ús.
  // També activa la primera càrrega de dades per mostrar les estadístiques reals.
  @override
  void initState() {
    super.initState();
    controller = UserStatsController();
    controller.initialize();
  }

  // Aquest mètode allibera el controller quan la pantalla deixa d’utilitzar-se.
  // Això evita mantenir escoltes actives o actualitzacions innecessàries.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla i la refresca quan el controller canvia.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final stats = controller.stats;

        // Aquest bloc mostra una pantalla de càrrega mentre encara no hi ha dades inicials.
        if (controller.isInitialLoading) {
          return const StatsLoadingState();
        }

        // Aquest bloc mostra un estat d’error quan no s’han pogut obtenir estadístiques.
        // També permet reintentar la càrrega sense sortir de la pantalla.
        if (stats == null) {
          return StatsErrorState(
            message: controller.errorMessage ??
                'No hi ha dades d\'estadístiques disponibles',
            onRetryTap: controller.onRetryTap,
          );
        }

        // Aquest bloc mostra el contingut principal de les estadístiques.
        // Les dades ja arriben preparades pel controller i es reparteixen entre widgets específics.
        return RefreshIndicator(
          onRefresh: controller.onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const Text(
                'Estadístiques',
                style: TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF141414),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'El teu progrés als cims de Catalunya',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5E6572),
                ),
              ),
              const SizedBox(height: 28),

              StatsMostAscendedCard(
                topAscendedPeaks: stats.topAscendedPeaks,
              ),
              const SizedBox(height: 14),

              StatsChallengeCard(
                current: controller.challengeCurrent,
                target: controller.challengeTarget,
                percentage: controller.challengePercentage,
              ),
              const SizedBox(height: 22),

              StatsHistoryCard(
                totalAscents: stats.totalAscents,
                monthlyAscents: stats.monthlyAscents,
                monthsToShow: 12,
              ),
              const SizedBox(height: 14),

              _StatsMonthlyStreakCard(
                current: stats.monthlyStreak.current,
                best: stats.monthlyStreak.best,
              ),
              const SizedBox(height: 14),

                            StatsRangeSelector(
                options: controller.rangeOptions,
                selectedRange: controller.selectedRange,
                onRangeSelected: controller.onRangeChanged,
              ),
              const SizedBox(height: 14),

              StatsTotalMetersCard(
                totalMeters: stats.totalAltitudeMeters,
                comparisonLabel: controller.monthlyComparisonLabel,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Aquesta targeta mostra la ratxa mensual d'ascensions.
// Una ratxa compta mesos consecutius amb almenys una ascensió registrada.
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