import 'package:cims/app/screens/peaks_catalog/widgets/peak_detail_card.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_empty_state.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_error_state.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el contingut principal del catàleg.
// Decideix si s’ha de veure una càrrega, un error, un estat buit o el llistat de cims.
class PeaksCatalogContent extends StatelessWidget {
  const PeaksCatalogContent({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.peaks,
    required this.currentSearch,
    required this.hasActiveFilters,
    required this.statusForPeak,
    required this.onRefresh,
    required this.onRetryTap,
    required this.onPeakTap,
  });

  // Aquest bloc rep l’estat necessari per representar el catàleg
  // sense accedir directament al controller de la pantalla.
  final bool isLoading;
  final String? errorMessage;
  final List<Peak> peaks;
  final String currentSearch;
  final bool hasActiveFilters;
  final PeakStatus? Function(int peakId) statusForPeak;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryTap;
  final ValueChanged<Peak> onPeakTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: _buildContent(),
    );
  }

  // Aquest mètode escull el contingut concret segons l’estat actual del catàleg.
  // Manté separats els casos d’error, llista buida i llista amb resultats.
  Widget _buildContent() {
    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 48),
        children: [
          PeaksErrorState(
            message: errorMessage!,
            onRetryTap: onRetryTap,
          ),
        ],
      );
    }

    if (peaks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 48),
        children: [
          PeaksEmptyState(
            currentSearch: currentSearch,
            hasActiveFilters: hasActiveFilters,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: peaks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        // Aquest bloc recupera el cim corresponent a cada posició
        // i el converteix en una targeta visual del llistat amb el seu estat personal.
        final peak = peaks[index];

        return PeakDetailCard(
          peak: peak,
          status: statusForPeak(peak.id),
          onTap: () => onPeakTap(peak),
        );
      },
    );
  }
}