import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/dashboard/dashboard_controller.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_challenge_card.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_monthly_challenge_card.dart';
import 'package:cims/app/screens/dashboard/widgets/dashboard_peak_section.dart';
import 'package:cims/app/screens/main_navigation/main_bottom_navigation_tab.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el resum principal de l’usuari després d’iniciar sessió.
// Actua com a entrada visual a l’aplicació i resumeix progrés, objectius, favorits i reptes.
@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Aquest estat connecta la pantalla amb el controller del dashboard.
// La UI només mostra dades i delega la càrrega, errors i navegació al controller.
class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  // Aquest mètode prepara el controller, activa l’escolta de navegació
  // i inicia la càrrega de dades quan la pantalla ja està construïda.
  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_handleNavigation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadDashboard();
    });
  }

  // Aquest mètode escolta les intencions de navegació generades pel controller.
  // Manté la navegació fora del controller i la resol des de la pantalla.
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

  // Aquest mètode allibera el controller i elimina l’escolta activa.
  // Evita mantenir referències de la pantalla quan ja no s’està mostrant.
  @override
  void dispose() {
    _controller.removeListener(_handleNavigation);
    _controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla segons l’estat actual:
  // càrrega inicial, error o contingut del dashboard.
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DashboardHeader(),
                    const SizedBox(height: 22),
                    DashboardChallengeCard(
                      challenge: summary.challengeProgress,
                      onViewStats: _controller.openStats,
                    ),
                    const SizedBox(height: 18),
                    DashboardMonthlyChallengeCard(
                      challenge: summary.monthlyChallenge,
                    ),
                    const SizedBox(height: 18),
                    DashboardPeakSection(
                      title: 'Pendents de coronar',
                      emptyMessage: 'Encara no tens cims pendents.',
                      peaks: summary.pendingPeaks,
                      icon: Icons.flag_rounded,
                      onPeakTap: _controller.openPeakDetail,
                    ),
                    const SizedBox(height: 18),
                    DashboardPeakSection(
                      title: 'Els meus preferits',
                      emptyMessage: 'Encara no tens cims preferits.',
                      peaks: summary.favoritePeaks,
                      icon: Icons.favorite_rounded,
                      onPeakTap: _controller.openPeakDetail,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Aquesta capçalera presenta el dashboard amb un missatge breu.
// Manté la pantalla alineada amb una experiència personal i orientada al progrés.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  // Aquest mètode construeix el títol principal i el text introductori del dashboard.
  // Ajuda l’usuari a entendre ràpidament el propòsit de la pantalla.
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF1F2933),
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Segueix el teu progrés i prepara els propers cims.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Aquest estat visual s’utilitza mentre es carreguen les dades inicials.
// Evita mostrar una pantalla buida durant la primera petició.
class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  // Aquest mètode mostra un indicador de càrrega centrat.
  // Informa l’usuari que el dashboard encara està obtenint les dades.
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0B57D0),
      ),
    );
  }
}

// Aquest estat visual mostra un error de càrrega i permet tornar-ho a provar.
// Dona una resposta clara quan el dashboard no pot obtenir les dades.
class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  // Aquestes dades defineixen el missatge d’error i l’acció de recuperació.
  // Permeten mostrar una incidència comprensible i donar una sortida a l’usuari.
  final String message;
  final VoidCallback onRetry;

  // Aquest mètode construeix el missatge d’error i el botó de reintent.
  // Manté la pantalla funcional encara que la càrrega inicial hagi fallat.
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
              child: const Text('Tornar-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
