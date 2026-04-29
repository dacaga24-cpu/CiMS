import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_google_map.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget concentra el contingut variable de la pantalla del mapa.
// Decideix si cal mostrar càrrega, error, estat buit o el mapa amb els cims.
class PeaksMapContent extends StatelessWidget {
  const PeaksMapContent({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.peaks,
    required this.selectedPeak,
    required this.currentSearch,
    required this.hasActiveFilters,
    required this.onRefresh,
    required this.onRetryTap,
    required this.onPeakTap,
    required this.onSelectedPeakDetailTap,
    required this.onMapTap,
    required this.selectedStatusFilter,
  });

  // Aquest bloc rep l’estat necessari per decidir què s’ha de mostrar.
  // Permet separar la lògica visual del mapa de la pantalla principal.
  final bool isLoading;
  final String? errorMessage;
  final List<Peak> peaks;
  final Peak? selectedPeak;
  final String currentSearch;
  final bool hasActiveFilters;
  final PeakStatusFilter selectedStatusFilter;

  // Aquest bloc rep les accions que el contingut pot comunicar a la pantalla.
  // Així el widget mostra la interfície, però no decideix com es carreguen o naveguen les dades.
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryTap;
  final ValueChanged<Peak> onPeakTap;
  final VoidCallback onSelectedPeakDetailTap;
  final VoidCallback onMapTap;

  // Construeix el contingut segons l’estat actual del mapa.
  // Si el mapa ja té cims carregats, no es desmunta durant una nova càrrega.
  @override
  Widget build(BuildContext context) {
    if (isLoading && peaks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null && peaks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _PeaksMapErrorState(
              message: errorMessage!,
              onRetryTap: onRetryTap,
            ),
          ],
        ),
      );
    }

    if (peaks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _PeaksMapEmptyState(
              currentSearch: currentSearch,
              hasActiveFilters: hasActiveFilters,
            ),
          ],
        ),
      );
    }

    // Quan hi ha cims disponibles, es mostra el mapa sense desmuntar-lo en recàrregues posteriors.
    // Això manté una experiència més fluida, especialment quan s’apliquen filtres o cerques.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PeaksGoogleMap(
            peaks: peaks,
            selectedPeak: selectedPeak,
            onPeakTap: onPeakTap,
            onSelectedPeakDetailTap: onSelectedPeakDetailTap,
            onMapTap: onMapTap,
            statusFilter: selectedStatusFilter,
          ),
        ),

        // Aquesta càrrega flotant evita desmuntar Google Maps mentre s’apliquen filtres.
        // En web és important perquè reconstruir el mapa complet pot bloquejar la interfície.
        if (isLoading)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(21),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Aquest widget mostra un missatge quan el mapa no pot carregar les dades.
// També permet repetir la càrrega sense sortir de la pantalla.
class _PeaksMapErrorState extends StatelessWidget {
  const _PeaksMapErrorState({
    required this.message,
    required this.onRetryTap,
  });

  final String message;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 44,
            color: Color(0xFF9AA3B2),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetryTap,
            child: const Text('Torna-ho a provar'),
          ),
        ],
      ),
    );
  }
}

// Aquest widget informa que no hi ha cims disponibles per mostrar al mapa.
// El text s’adapta si l’usuari ha aplicat cerca o filtres.
class _PeaksMapEmptyState extends StatelessWidget {
  const _PeaksMapEmptyState({
    required this.currentSearch,
    required this.hasActiveFilters,
  });

  final String currentSearch;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final hasSearch = currentSearch.isNotEmpty;

    String message = 'Encara no hi ha cims amb ubicació disponible';

    if (hasSearch && hasActiveFilters) {
      message =
          'No s\'han trobat cims al mapa amb aquesta cerca i aquests filtres';
    } else if (hasSearch) {
      message = 'No s\'han trobat cims al mapa per a aquesta cerca';
    } else if (hasActiveFilters) {
      message = 'No s\'han trobat cims al mapa amb els filtres aplicats';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(
            Icons.map_outlined,
            size: 44,
            color: Color(0xFF9AA3B2),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }
}
