import 'package:cims/core/entity/dashboard_summary.dart';

// Aquest cas d’ús recupera les dades necessàries per construir el dashboard.
// De moment retorna dades simulades per permetre avançar el frontend mentre
// el backend acaba d’incorporar els camps pendents.
class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase();

  // Aquest mètode representa la càrrega del resum del dashboard.
  // Més endavant substituirà aquestes dades mock per una crida real a l'ApiClient.
  Future<DashboardSummary> execute() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const DashboardSummary(
      completedPeaks: 64,
      activeTargets: 8,
      favorites: 5,
      totalAscents: 72,
      uniquePeaksAscended: 64,
      totalAltitudeMeters: 84250,
      challengeProgress: ChallengeProgress(
        completed: 64,
        target: 100,
        remaining: 36,
        percentage: 64,
      ),
      pendingPeaks: [
        DashboardPeakItem(
          id: 1,
          name: 'Puigmal',
          altitude: 2910,
          regionName: 'Ripollès',
        ),
        DashboardPeakItem(
          id: 2,
          name: 'Pedraforca',
          altitude: 2506,
          regionName: 'Berguedà',
        ),
        DashboardPeakItem(
          id: 3,
          name: 'Matagalls',
          altitude: 1697,
          regionName: 'Osona',
        ),
      ],
      favoritePeaks: [
        DashboardPeakItem(
          id: 4,
          name: 'Canigó',
          altitude: 2784,
          regionName: 'Conflent',
        ),
        DashboardPeakItem(
          id: 5,
          name: 'La Mola',
          altitude: 1104,
          regionName: 'Vallès Occidental',
        ),
        DashboardPeakItem(
          id: 6,
          name: 'Taga',
          altitude: 2040,
          regionName: 'Ripollès',
        ),
      ],
      monthlyChallenge: MonthlyChallenge(
        current: 2,
        target: 4,
        percentage: 50,
        unit: 'ascensions',
        title: 'Repte mensual',
        description: 'Completa 4 ascensions aquest mes.',
      ),
      recentAscents: [
        DashboardRecentAscent(
          id: 1,
          peakId: 4,
          peakName: 'Canigó',
          ascentDate: '2026-04-20',
          altitude: 2784,
          regionName: 'Conflent',
        ),
        DashboardRecentAscent(
          id: 2,
          peakId: 5,
          peakName: 'La Mola',
          ascentDate: '2026-04-14',
          altitude: 1104,
          regionName: 'Vallès Occidental',
        ),
      ],
      lastAscent: DashboardRecentAscent(
        id: 1,
        peakId: 4,
        peakName: 'Canigó',
        ascentDate: '2026-04-20',
        altitude: 2784,
        regionName: 'Conflent',
      ),
      highestCompletedAltitude: DashboardPeakItem(
        id: 1,
        name: 'Puigmal',
        altitude: 2910,
        regionName: 'Ripollès',
      ),
      mostAscendedPeak: DashboardPeakItem(
        id: 5,
        name: 'La Mola',
        altitude: 1104,
        regionName: 'Vallès Occidental',
        ascentCount: 3,
      ),
      monthlyAscents: [
        MonthlyAscentsItem(month: '2026-01', total: 2),
        MonthlyAscentsItem(month: '2026-02', total: 3),
        MonthlyAscentsItem(month: '2026-03', total: 1),
        MonthlyAscentsItem(month: '2026-04', total: 4),
      ],
    );
  }
}