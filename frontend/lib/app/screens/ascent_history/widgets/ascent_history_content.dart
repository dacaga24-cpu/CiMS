import 'package:cims/app/screens/ascent_history/widgets/ascent_history_empty_state.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_error_state.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_header.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_timeline.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa el contingut principal de la pantalla d’historial.
// Decideix si cal mostrar càrrega, error, estat buit o la línia temporal d’ascensions.
class AscentHistoryContent extends StatelessWidget {
  const AscentHistoryContent({
    super.key,
    required this.peakName,
    required this.altitude,
    required this.regions,
    required this.ascents,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onRetryTap,
    required this.onAscentTap,
  });

  // Aquest bloc rep la informació del cim i l’estat de les ascensions carregades.
  // Així la pantalla principal no necessita conèixer els detalls de construcció del layout.
  final String peakName;
  final int altitude;
  final List<String> regions;
  final List<Ascent> ascents;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryTap;
  final ValueChanged<Ascent> onAscentTap;

  // Aquest mètode construeix una vista refrescable amb la capçalera del cim
  // i el bloc inferior de darreres ascensions.
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          AscentHistoryHeader(
            peakName: peakName,
            altitude: altitude,
            regions: regions,
            totalAscents: ascents.length,
          ),
          const SizedBox(height: 30),
          if (errorMessage != null)
            AscentHistoryErrorState(
              message: errorMessage!,
              onRetryTap: onRetryTap,
            )
          else if (ascents.isEmpty)
            const AscentHistoryEmptyState()
          else
            AscentHistoryTimeline(
              ascents: ascents,
              onAscentTap: onAscentTap,
            ),
        ],
      ),
    );
  }
}