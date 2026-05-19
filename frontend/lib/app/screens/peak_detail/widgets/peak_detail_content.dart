import 'package:cims/app/screens/peak_detail/widgets/peak_detail_description_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_empty_state.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_error_state.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_header.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_map_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_status_actions.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_status_messages.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_weather_card.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/entity/peak_weather.dart';
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
    required this.weatherForecast,
    required this.isWeatherLoading,
    required this.weatherErrorMessage,
    required this.expandedWeatherDay,
    required this.expandedWeatherHourly,
    required this.isExpandedHourlyLoading,
    required this.expandedHourlyError,
    required this.onRetryTap,
    required this.onTargetTap,
    required this.onFavoriteTap,
    required this.onMapTap,
    required this.onWeatherRetryTap,
    required this.onWeatherDayTap,
    required this.onWeatherHourlyRetryTap,
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
  final PeakWeather? weatherForecast;
  final bool isWeatherLoading;
  final String? weatherErrorMessage;
  final String? expandedWeatherDay;
  final PeakHourlyWeather? expandedWeatherHourly;
  final bool isExpandedHourlyLoading;
  final String? expandedHourlyError;
  final Future<void> Function() onRetryTap;
  final VoidCallback onTargetTap;
  final VoidCallback onFavoriteTap;
  final Future<void> Function(int peakId) onMapTap;
  final Future<void> Function() onWeatherRetryTap;
  final void Function(String date) onWeatherDayTap;
  final Future<void> Function(String date) onWeatherHourlyRetryTap;

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
            isCompleted: peakStatus?.isCompleted ?? false,
            hasVerifiedAscent: peakStatus?.hasVerifiedAscent ?? false,
          ),
          const SizedBox(height: 18),
          PeakDetailStatusActions(
            isTarget: peakStatus?.isTarget ?? false,
            isFavorite: peakStatus?.isFavorite ?? false,
            areActionsEnabled: !isUpdatingStatus,
            onTargetTap: onTargetTap,
            onFavoriteTap: onFavoriteTap,
          ),
          PeakDetailStatusMessages(
            statusErrorMessage: statusErrorMessage,
            ascentsErrorMessage: ascentsErrorMessage,
          ),
          // La descripció es mostra abans de la previsió meteorològica
          // perquè doni context del cim immediatament després de les
          // accions principals. La previsió queda més avall com a
          // informació complementària per planificar la sortida.
          if (currentPeak.hasDescription) ...[
            const SizedBox(height: 18),
            PeakDetailDescriptionCard(
              peak: currentPeak,
            ),
          ],
          const SizedBox(height: 18),
          PeakDetailWeatherCard(
            forecast: weatherForecast,
            isLoading: isWeatherLoading,
            errorMessage: weatherErrorMessage,
            onRetryTap: onWeatherRetryTap,
            expandedDay: expandedWeatherDay,
            expandedHourly: expandedWeatherHourly,
            isExpandedHourlyLoading: isExpandedHourlyLoading,
            expandedHourlyError: expandedHourlyError,
            onDayTap: onWeatherDayTap,
            onHourlyRetryTap: onWeatherHourlyRetryTap,
          ),
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
