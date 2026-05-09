import 'package:cims/app/screens/peak_detail/widgets/peak_detail_description_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_empty_state.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_error_state.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_header.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_map_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_status_actions.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_status_messages.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/material.dart';

// Aquest widget decideix quin contingut s’ha de mostrar dins del detall del cim.
// Agrupa els estats de càrrega, error, buit i contingut principal perquè la screen sigui més lleugera.
class PeakDetailContent extends StatelessWidget {
  const PeakDetailContent({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.peak,
    required this.peakStatus,
    required this.lastAscentDate,
    required this.isUpdatingStatus,
    required this.statusErrorMessage,
    required this.ascentsErrorMessage,
    required this.onRetryTap,
    required this.onTargetTap,
    required this.onFavoriteTap,
    required this.onMapTap,
  });

  // Aquest bloc rep l’estat necessari per representar el detall
  // sense accedir directament al controller de la pantalla.
  final bool isLoading;
  final String? errorMessage;
  final Peak? peak;
  final PeakStatus? peakStatus;
  final DateTime? lastAscentDate;
  final bool isUpdatingStatus;
  final String? statusErrorMessage;
  final String? ascentsErrorMessage;
  final Future<void> Function() onRetryTap;
  final VoidCallback onTargetTap;
  final VoidCallback onFavoriteTap;
  final Future<void> Function(int peakId) onMapTap;

  // Aquest mètode construeix el contingut visual segons l’estat actual de les dades.
  // Permet mostrar una càrrega, un error, un estat buit o el detall complet del cim.
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return PeakDetailErrorState(
        message: errorMessage!,
        onRetryTap: onRetryTap,
      );
    }

    final currentPeak = peak;
    if (currentPeak == null) {
      return const PeakDetailEmptyState();
    }

    // Quan el cim existeix, es mostra el detall complet en una llista refrescable.
    // Això permet tornar a carregar la informació si l’usuari arrossega la pantalla cap avall.
    return RefreshIndicator(
      onRefresh: onRetryTap,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          PeakDetailHeader(
            peak: currentPeak,
            lastAscentDate: lastAscentDate,
          ),
          const SizedBox(height: 18),
          PeakDetailStatusActions(
            isTarget: peakStatus?.isTarget ?? false,
            isCompleted: peakStatus?.isCompleted ?? false,
            isFavorite: peakStatus?.isFavorite ?? false,
            areActionsEnabled: !isUpdatingStatus,
            onTargetTap: onTargetTap,
            onFavoriteTap: onFavoriteTap,
          ),
          PeakDetailStatusMessages(
            statusErrorMessage: statusErrorMessage,
            ascentsErrorMessage: ascentsErrorMessage,
          ),
          if (currentPeak.hasDescription) ...[
            const SizedBox(height: 18),
            PeakDetailDescriptionCard(
              peak: currentPeak,
            ),
          ],
          const SizedBox(height: 18),
          PeakDetailMapCard(
            peak: currentPeak,
            onTap: () {
              onMapTap(currentPeak.id);
            },
          ),
        ],
      ),
    );
  }
}
