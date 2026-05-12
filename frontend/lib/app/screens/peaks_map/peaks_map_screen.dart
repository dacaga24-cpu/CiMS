import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_active_filters_summary.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_filters_sheet.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_search_bar.dart';
import 'package:cims/app/screens/peaks_map/peaks_map_controller.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_content.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el mapa de cims de l’aplicació.
// Permet consultar els cims sobre Google Maps, aplicar cerca i filtres,
// modificar estats ràpids del cim seleccionat i obrir-ne el detall.
@RoutePage()
class PeaksMapScreen extends StatefulWidget {
  const PeaksMapScreen({
    super.key,
    this.initialPeakId,
  });

  // Identificador opcional del cim que s’ha de seleccionar en obrir el mapa.
  // S’utilitza quan l’usuari arriba al mapa des de la pantalla de detall d’un cim.
  final int? initialPeakId;

  @override
  State<PeaksMapScreen> createState() => _PeaksMapScreenState();
}

// Aquesta classe gestiona la vida interna de la pantalla del mapa.
// Crea el controller, escolta els seus canvis i resol la navegació cap al detall.
class _PeaksMapScreenState extends State<PeaksMapScreen> {
  // Aquest controller concentra l’estat i les accions de la pantalla.
  // La vista el fa servir per mostrar dades, aplicar filtres i reaccionar a la navegació.
  late final PeaksMapController controller;

  // Inicialitza el controller quan es crea la pantalla.
  // També registra l’escolta de canvis i inicia la càrrega de dades del mapa.
  @override
  void initState() {
    super.initState();
    controller = PeaksMapController(
      initialPeakId: widget.initialPeakId,
    )
      ..addListener(_handleControllerChanges)
      ..initialize();
  }

  // Reacciona als canvis del controller que afecten la navegació.
  // Quan hi ha un cim seleccionat per obrir, consumeix l’acció i envia l’usuari al detall.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == PeaksMapDestination.peakDetail) {
      final peakId = controller.selectedPeakId;
      controller.consumeNavigation();

      if (peakId != null) {
        _openPeakDetail(peakId);
      }
    }
  }

  // Obre la pantalla de detall del cim indicat.
  // Rep l’identificador del cim perquè la pantalla de detall pugui carregar-ne la informació.
  Future<void> _openPeakDetail(int peakId) async {
    await context.router.root.push(
      PeakDetailRoute(peakId: peakId),
    );
  }

  // Mostra el full inferior amb els filtres del mapa.
  // Passa els valors actuals del controller perquè l’usuari pugui modificar-los o netejar-los.
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

  // Allibera els recursos associats a la pantalla.
  // També elimina l’escolta del controller per evitar notificacions quan la vista ja no existeix.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Construeix la interfície principal del mapa.
  // AnimatedBuilder permet reconstruir la pantalla quan el controller actualitza el seu estat.
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
                PeaksSearchBar(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  onFilterTap: _openFiltersSheet,
                  hasActiveFilters: controller.hasActiveFilters,
                ),
                if (controller.hasActiveFilters) ...[
                  const SizedBox(height: 12),
                  PeaksActiveFiltersSummary(
                    summary: controller.activeFiltersSummary,
                    onClear: controller.clearFilters,
                  ),
                ],
                const SizedBox(height: 18),
                Expanded(
                  child: PeaksMapContent(
                    isLoading: controller.isLoading,
                    errorMessage: controller.errorMessage,
                    peaks: controller.peaks,
                    selectedPeak: controller.selectedPeak,
                    currentSearch: controller.currentSearch,
                    hasActiveFilters: controller.hasActiveFilters,
                    selectedStatusFilter: controller.selectedStatusFilter,
                    statusForPeak: controller.statusForPeak,
                    onRefresh: controller.onRetryTap,
                    onRetryTap: controller.onRetryTap,
                    onPeakTap: controller.onPeakSelected,
                    onSelectedPeakDetailTap: controller.onSelectedPeakDetailTap,
                    onSelectedPeakTargetTap:
                        controller.isUpdatingSelectedPeakStatus
                            ? null
                            : controller.onSelectedPeakTargetTap,
                    onSelectedPeakFavoriteTap:
                        controller.isUpdatingSelectedPeakStatus
                            ? null
                            : controller.onSelectedPeakFavoriteTap,
                    onMapTap: controller.clearSelectedPeak,
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