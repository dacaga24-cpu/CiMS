import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/peaks_catalog_controller.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_active_filters_summary.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_catalog_content.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_filters_sheet.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_search_bar.dart';
import 'package:flutter/material.dart';

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
  // incloent la càrrega inicial, la cerca, els filtres,
  // els estats personals dels cims i la navegació cap al detall.
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
        _openPeakDetail(peakId);
      }
    }
  }

  // Aquest mètode obre el detall del cim i refresca els estats personals
  // quan l’usuari torna al catàleg després d’haver-hi fet canvis.
  Future<void> _openPeakDetail(int peakId) async {
    await context.router.root.push(
      PeakDetailRoute(peakId: peakId),
    );

    if (!mounted) return;

    await controller.reloadStatuses();
  }

  // Aquest mètode obre el panell flotant de filtres.
  // Es mostra sobre la pantalla actual per mantenir visible el llistat del darrere.
  Future<void> _openFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) {
        return PeaksFiltersSheet(
          availableRegions: controller.availableRegions,
          initialRegionId: controller.selectedRegionId,
          initialMinAltitude: controller.minAltitude,
          initialMaxAltitude: controller.maxAltitude,
          initialStatusFilter: controller.selectedStatusFilter,
          onApply: ({
            int? regionId,
            int? minAltitude,
            int? maxAltitude,
            PeakStatusFilter statusFilter = PeakStatusFilter.none,
          }) {
            controller.applyFilters(
              regionId: regionId,
              minAltitude: minAltitude,
              maxAltitude: maxAltitude,
              statusFilter: statusFilter,
            );
          },
          onClear: controller.clearFilters,
        );
      },
    );
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

                // Aquest bloc mostra la barra de cerca del catàleg
                // i el botó que obre el panell de filtres.
                PeaksSearchBar(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  onFilterTap: _openFiltersSheet,
                  hasActiveFilters: controller.hasActiveFilters,
                ),

                // Aquest bloc només apareix quan hi ha filtres aplicats.
                // Mostra un resum breu i permet netejar-los sense obrir el panell.
                if (controller.hasActiveFilters) ...[
                  const SizedBox(height: 12),
                  PeaksActiveFiltersSummary(
                    summary: controller.activeFiltersSummary,
                    onClear: controller.clearFilters,
                  ),
                ],

                const SizedBox(height: 18),

                // Aquest widget concentra el contingut variable del catàleg:
                // càrrega, error, estat buit o llistat de cims.
                Expanded(
                  child: PeaksCatalogContent(
                    isLoading: controller.isLoading,
                    errorMessage: controller.errorMessage,
                    peaks: controller.peaks,
                    currentSearch: controller.currentSearch,
                    hasActiveFilters: controller.hasActiveFilters,
                    statusForPeak: controller.statusForPeak,
                    onRefresh: controller.onRetryTap,
                    onRetryTap: controller.onRetryTap,
                    onPeakTap: controller.onPeakTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}