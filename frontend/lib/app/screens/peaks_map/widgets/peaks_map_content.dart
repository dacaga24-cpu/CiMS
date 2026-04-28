import 'package:cims/app/screens/peaks_map/widgets/peaks_map_placeholder.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_selected_peak_card.dart';
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
  });

  // Aquest bloc rep l’estat necessari per decidir què s’ha de mostrar.
  // Permet separar la lògica visual del mapa de la pantalla principal.
  final bool isLoading;
  final String? errorMessage;
  final List<Peak> peaks;
  final Peak? selectedPeak;
  final String currentSearch;
  final bool hasActiveFilters;

  // Aquest bloc rep les accions que el contingut pot comunicar a la pantalla.
  // Així el widget mostra la interfície, però no decideix com es carreguen o naveguen les dades.
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryTap;
  final ValueChanged<Peak> onPeakTap;
  final VoidCallback onSelectedPeakDetailTap;

  // Construeix el contingut segons l’estat actual del mapa.
  // Mostra càrrega, error, estat buit o el mapa amb la targeta del cim seleccionat.
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (errorMessage != null)
            _PeaksMapErrorState(
              message: errorMessage!,
              onRetryTap: onRetryTap,
            )
          else if (peaks.isEmpty)
            _PeaksMapEmptyState(
              currentSearch: currentSearch,
              hasActiveFilters: hasActiveFilters,
            )
          else ...[
            PeaksMapPlaceholder(
              peaks: peaks,
              selectedPeak: selectedPeak,
              onPeakTap: onPeakTap,
            ),
            const SizedBox(height: 16),
            if (selectedPeak != null)
              PeaksMapSelectedPeakCard(
                peak: selectedPeak!,
                onDetailTap: onSelectedPeakDetailTap,
              )
            else
              const _PeaksMapHintCard(),
          ],
        ],
      ),
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

  // Aquest bloc conté el missatge d’error i l’acció per reintentar la càrrega.
  final String message;
  final Future<void> Function() onRetryTap;

  // Construeix l’estat d’error amb una explicació clara i una acció de recuperació.
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

  // Aquest bloc permet adaptar el missatge segons el context de la consulta.
  // Diferencia entre absència de dades, cerca sense resultats o filtres massa restrictius.
  final String currentSearch;
  final bool hasActiveFilters;

  // Construeix l’estat buit amb un missatge entenedor per a l’usuari.
  @override
  Widget build(BuildContext context) {
    final hasSearch = currentSearch.isNotEmpty;

    String message = 'Encara no hi ha cims amb ubicació disponible';

    if (hasSearch && hasActiveFilters) {
      message = 'No s\'han trobat cims al mapa amb aquesta cerca i aquests filtres';
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

// Aquesta targeta dona una indicació inicial abans que l’usuari seleccioni un cim.
class _PeaksMapHintCard extends StatelessWidget {
  const _PeaksMapHintCard();

  // Mostra una ajuda breu perquè l’usuari entengui com interactuar amb el mapa.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Selecciona un punt del mapa per veure la informació bàsica del cim.',
        style: TextStyle(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: Color(0xFF5B6573),
        ),
      ),
    );
  }
}