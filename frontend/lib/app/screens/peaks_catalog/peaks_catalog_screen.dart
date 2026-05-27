import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/peaks_catalog_controller.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_active_filters_summary.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_catalog_content.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_filters_sheet.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_search_bar.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_sort_order_button.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_sort_order_sheet.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el catàleg de cims.
// Permet cercar, filtrar, ordenar, carregar més resultats i obrir el detall d’un cim.
@RoutePage()
class PeaksCatalogScreen extends StatefulWidget {
  const PeaksCatalogScreen({super.key});

  @override
  State<PeaksCatalogScreen> createState() => _PeaksCatalogScreenState();
}

class _PeaksCatalogScreenState extends State<PeaksCatalogScreen> {
  late final PeaksCatalogController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = PeaksCatalogController()
      ..addListener(_handleControllerChanges)
      ..initialize();

    _scrollController.addListener(_handleScroll);
  }

  // Aquest mètode detecta quan l’usuari s’apropa al final del llistat.
  // En aquest punt demana una nova pàgina de cims al controller.
  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final remainingScroll = position.maxScrollExtent - position.pixels;

    if (remainingScroll <= 280) {
      controller.loadMorePeaks();
    }
  }

  // Aquest mètode resol les navegacions demanades pel controller.
  // Quan s’ha seleccionat un cim, obre la pantalla de detall corresponent.
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

  // Aquest mètode obre el detall del cim seleccionat.
  Future<void> _openPeakDetail(int peakId) async {
    await context.router.root.push(
      PeakDetailRoute(peakId: peakId),
    );
  }

  // Aquest mètode obre el panell de filtres del catàleg.
  // Passa els valors actuals perquè el panell comenci amb l’estat vigent.
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

  // Aquest mètode obre el panell d’ordenació del catàleg.
  // El canvi seleccionat es delega al controller, que recarrega el llistat.
  Future<void> _openSortOrderSheet() {
    return PeaksSortOrderSheet.show(
      context,
      sortBy: controller.sortBy,
      sortOrder: controller.sortOrder,
      onSelected: (sortBy, sortOrder) {
        unawaited(
          controller.onSortChanged(sortBy: sortBy, sortOrder: sortOrder),
        );
      },
    );
  }

  // Aquest mètode allibera els recursos de la pantalla.
  // També elimina listeners per evitar notificacions sobre una vista tancada.
  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: AppResponsive.pagePadding(
              context,
              compactHorizontal: 16,
              compactTop: 12,
              compactBottom: 0,
              mediumBottom: 0,
              expandedBottom: 0,
            ),
            child: ResponsiveConstrainedBox(
              child: Column(
                children: [
                  SizedBox(
                    height: AppResponsive.isCompact(context) ? 20 : 8,
                  ),
                  PeaksSearchBar(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    onFilterTap: _openFiltersSheet,
                    hasActiveFilters: controller.hasActiveFilters,
                    trailingAction: PeaksSortOrderButton(
                      sortBy: controller.sortBy,
                      sortOrder: controller.sortOrder,
                      isLoading: controller.isLoading,
                      onTap: _openSortOrderSheet,
                    ),
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
                    child: PeaksCatalogContent(
                      scrollController: _scrollController,
                      isLoading: controller.isLoading,
                      isLoadingMore: controller.isLoadingMore,
                      errorMessage: controller.errorMessage,
                      loadMoreErrorMessage: controller.loadMoreErrorMessage,
                      peaks: controller.peaks,
                      currentSearch: controller.currentSearch,
                      hasActiveFilters: controller.hasActiveFilters,
                      statusForPeak: controller.statusForPeak,
                      onRefresh: controller.onRetryTap,
                      onRetryTap: controller.onRetryTap,
                      onLoadMoreRetryTap: controller.loadMorePeaks,
                      onPeakTap: controller.onPeakTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}