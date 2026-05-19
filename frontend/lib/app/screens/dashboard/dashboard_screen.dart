import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/dashboard/dashboard_controller.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_monthly_challenge_card.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_peak_section.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_recent_ascents_section.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_recent_photos_carousel.dart';
import 'package:cims/app/screens/main_navigation/main_bottom_navigation_tab.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/models/peaks_filter_state.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:flutter/material.dart';

@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_handleNavigation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadDashboard();
    });
  }

  void _handleNavigation() {
    if (!mounted) return;

    switch (_controller.destination) {
      case DashboardDestination.none:
        return;
      case DashboardDestination.peakDetail:
        final peakId = _controller.selectedPeakId;
        _controller.consumeNavigation();

        if (peakId == null) return;

        context.router.root.push(
          PeakDetailRoute(peakId: peakId),
        );
        return;
      case DashboardDestination.stats:
        _controller.consumeNavigation();

        AutoTabsRouter.of(context).setActiveIndex(
          MainBottomNavigationTab.stats.index,
        );
        return;
    }
  }

  void _openAscentHistory(DashboardRecentAscent ascent) {
    context.router.root.push(
      AscentHistoryRoute(
        peakId: ascent.peakId,
        peakName: ascent.peakName,
        altitude: ascent.altitude ?? 0,
        regions: ascent.regionName == null ? const [] : [ascent.regionName!],
      ),
    );
  }

  void _openCatalogWithStatusFilter(PeakStatusFilter statusFilter) {
    PeaksFilterState.shared.clear();
    PeaksFilterState.shared.apply(statusFilter: statusFilter);

    AutoTabsRouter.of(context).setActiveIndex(
      MainBottomNavigationTab.catalog.index,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleNavigation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.summary == null) {
              return const _DashboardLoadingState();
            }

            if (_controller.errorMessage != null &&
                _controller.summary == null) {
              return _DashboardErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.retry,
              );
            }

            final summary = _controller.summary;
            if (summary == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              onRefresh: _controller.loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                // En mòbil el FAB de càmera flota sobre el bottom navigation
                // bar, així que afegim espai extra a sota per evitar que
                // l'última ascensió quedi tapada per la flotant.
                padding: AppResponsive.pagePadding(
                  context,
                  compactHorizontal: 20,
                  compactTop: 18,
                  compactBottom: 96,
                ),
                child: ResponsiveConstrainedBox(
                  child: _DashboardContent(
                    summary: summary,
                    onPeakTap: _controller.openPeakDetail,
                    onViewGalleryTap: () {
                      context.router.root.push(
                        const UserPhotoGalleryRoute(),
                      );
                    },
                    onStatusFilterTap: _openCatalogWithStatusFilter,
                    onAscentTap: _openAscentHistory,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.summary,
    required this.onPeakTap,
    required this.onViewGalleryTap,
    required this.onStatusFilterTap,
    required this.onAscentTap,
  });

  final DashboardSummary summary;
  final ValueChanged<int> onPeakTap;
  final VoidCallback onViewGalleryTap;
  final ValueChanged<PeakStatusFilter> onStatusFilterTap;
  final ValueChanged<DashboardRecentAscent> onAscentTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppResponsive.isCompact(context);

    if (isCompact) {
      return _DashboardColumn(
        children: _allSections,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return _DashboardColumn(
            children: _allSections,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardHeader(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _DashboardColumn(
                    children: [
                      _challengeCard,
                      _photosCard,
                      _recentAscentsCard,
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: _DashboardColumn(
                    children: [
                      _targetPeaksCard,
                      _favoritePeaksCard,
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> get _allSections {
    return [
      const _DashboardHeader(),
      _challengeCard,
      _photosCard,
      _targetPeaksCard,
      _favoritePeaksCard,
      _recentAscentsCard,
    ];
  }

  Widget get _challengeCard {
    return DashboardMonthlyChallengeCard(
      challenge: summary.monthlyChallenge,
    );
  }

  Widget get _photosCard {
    return DashboardRecentPhotosCarousel(
      photos: summary.recentPhotos,
      onViewGalleryTap: onViewGalleryTap,
    );
  }

  Widget get _targetPeaksCard {
    return DashboardPeakSection(
      title: 'Últims objectius',
      emptyMessage: 'Encara no tens cap cim com a objectiu.',
      peaks: summary.pendingPeaks,
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFFF97316),
      onPeakTap: onPeakTap,
      onViewAllTap: () => onStatusFilterTap(PeakStatusFilter.target),
    );
  }

  Widget get _favoritePeaksCard {
    return DashboardPeakSection(
      title: 'Últims preferits',
      emptyMessage: 'Encara no tens cims preferits.',
      peaks: summary.favoritePeaks,
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFE84A4A),
      onPeakTap: onPeakTap,
      onViewAllTap: () => onStatusFilterTap(PeakStatusFilter.favorite),
    );
  }

  Widget get _recentAscentsCard {
    return DashboardRecentAscentsSection(
      ascents: summary.recentAscents,
      onAscentTap: onAscentTap,
      onViewAllTap: () => onStatusFilterTap(PeakStatusFilter.completed),
    );
  }
}

class _DashboardColumn extends StatelessWidget {
  const _DashboardColumn({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacedChildren = <Widget>[];

    for (final child in children) {
      if (child is SizedBox && child.height == 0 && child.width == 0) {
        continue;
      }

      if (spacedChildren.isNotEmpty) {
        spacedChildren.add(const SizedBox(height: 18));
      }

      spacedChildren.add(child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spacedChildren,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSession.userProfileStore,
      builder: (context, _) {
        final user = AppSession.userProfileStore.user;
        final firstName = user?.firstName.trim() ?? '';
        final greetingName = firstName.isEmpty ? 'explorador' : firstName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bon dia, $greetingName',
              style: const TextStyle(
                color: Color(0xFF1F2933),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Segueix el teu progrés i prepara els propers cims.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0B57D0),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB42318),
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1F2933),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B57D0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text("Tornar-ho a provar"),
            ),
          ],
        ),
      ),
    );
  }
}
