import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:flutter/material.dart';

import 'peaks_catalog_controller.dart';
import 'widgets/peak_detail_card.dart';
import 'widgets/peaks_search_bar.dart';

// Aquesta pantalla mostra el catàleg de cims de l’aplicació.
// La seva funció és construir la vista general del llistat i connectar-la
// amb el controller, que és qui gestiona l’estat i les dades.
@RoutePage()
class PeaksCatalogScreen extends StatefulWidget {
  const PeaksCatalogScreen({super.key});

  @override
  State<PeaksCatalogScreen> createState() => _PeaksCatalogScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla del catàleg.
// S’encarrega de preparar el controller, escoltar-ne els canvis
// i construir la interfície segons l’estat actual de les dades.
class _PeaksCatalogScreenState extends State<PeaksCatalogScreen> {
  // Aquest controlador concentra les dades i l’estat del catàleg,
  // incloent la càrrega inicial, la cerca i la navegació cap al detall.
  late final PeaksCatalogController controller;

  // Aquest mètode prepara el controller quan la pantalla es crea
  // i inicia la càrrega inicial de les dades que es mostraran al catàleg.
  @override
  void initState() {
    super.initState();
    controller = PeaksCatalogController()
      ..addListener(_handleControllerChanges)
      ..initialize();
  }

  // Aquest mètode escolta els canvis del controller i resol la navegació real
  // des de la vista, mantenint el controller desacoblat de la UI.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == PeaksCatalogDestination.peakDetail) {
      final peakId = controller.selectedPeakId;
      controller.consumeNavigation();

      if (peakId != null) {
        context.router.root.push(
          PeakDetailRoute(peakId: peakId),
        );
      }
    }
  }

  // Aquest mètode allibera els recursos associats al controller
  // quan la pantalla deixa d’existir.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la interfície de la pantalla i la reactualitza
  // quan canvia l’estat del controller.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Aquest bloc mostra la barra de cerca del catàleg.
                // El botó de filtres queda visible però reservat per a una futura tasca.
                PeaksSearchBar(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  onFilterTap: () {},
                ),
                const SizedBox(height: 18),

                // Aquest espai principal mostra un indicador de càrrega,
                // un estat d’error o la llista real del catàleg segons convingui.
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : RefreshIndicator(
                          onRefresh: controller.onRetryTap,
                          child: _buildContent(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Aquest mètode decideix quin contingut principal s’ha de veure.
  // D’aquesta manera la lògica dels estats queda agrupada i la build principal és més clara.
  Widget _buildContent() {
    if (controller.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 48),
        children: [
          _buildErrorState(),
        ],
      );
    }

    if (controller.peaks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 48),
        children: [
          _buildEmptyState(),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: controller.peaks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        // Aquest bloc recupera el cim corresponent a cada posició
        // i el converteix en una targeta visual del llistat.
        final peak = controller.peaks[index];

        return PeakDetailCard(
          peak: peak,
          onTap: () => controller.onPeakTap(peak),
        );
      },
    );
  }

  // Aquest bloc mostra un missatge senzill quan la cerca no retorna resultats.
  Widget _buildEmptyState() {
    final hasSearch = controller.currentSearch.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(
              Icons.landscape_outlined,
              size: 44,
              color: Color(0xFF9AA3B2),
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch
                  ? 'No s\'han trobat cims per a aquesta cerca'
                  : 'Encara no hi ha cims disponibles',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Aquest bloc mostra un missatge d’error quan la càrrega del catàleg falla.
  // També ofereix una acció directa per tornar-ho a provar.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFF9AA3B2),
            ),
            const SizedBox(height: 14),
            Text(
              controller.errorMessage ?? 'No s\'ha pogut carregar el catàleg',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.onRetryTap,
              child: const Text('Torna-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
