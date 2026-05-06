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
    required this.scrollController,
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.loadMoreErrorMessage,
    required this.peaks,
    required this.currentSearch,
    required this.hasActiveFilters,
    required this.statusForPeak,
    required this.onRefresh,
    required this.onRetryTap,
    required this.onLoadMoreRetryTap,
    required this.onPeakTap,
  });

  // Aquest controlador permet detectar el final del llistat des de la pantalla.
  final ScrollController scrollController;

  // Aquest bloc rep l’estat necessari per representar el catàleg
  // sense accedir directament al controller de la pantalla.
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreErrorMessage;
  final List<Peak> peaks;
  final String currentSearch;
  final bool hasActiveFilters;
  final PeakStatus? Function(int peakId) statusForPeak;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryTap;
  final Future<void> Function() onLoadMoreRetryTap;
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
        controller: scrollController,
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
        controller: scrollController,
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

    final hasFooter = isLoadingMore || loadMoreErrorMessage != null;

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: peaks.length + (hasFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == peaks.length) {
          return _LoadMoreFooter(
            isLoadingMore: isLoadingMore,
            errorMessage: loadMoreErrorMessage,
            onRetryTap: onLoadMoreRetryTap,
          );
        }

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

// Aquest widget mostra l’estat de càrrega de pàgines addicionals.
// També permet repetir la càrrega si falla una pàgina posterior.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoadingMore,
    required this.errorMessage,
    required this.onRetryTap,
  });

  final bool isLoadingMore;
  final String? errorMessage;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    final message = errorMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE84A4A),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetryTap,
            child: const Text('Torna-ho a provar'),
          ),
        ],
      ),
    );
  }
}
