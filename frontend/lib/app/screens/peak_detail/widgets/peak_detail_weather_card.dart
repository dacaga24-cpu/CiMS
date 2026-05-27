import 'package:cims/app/widgets/weather/weather_visuals.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';
import 'package:cims/core/entity/peak_weather.dart';
import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// Aquest widget mostra la previsió meteorològica del cim.
// Combina la previsió diària amb un panell horari desplegable per a cada dia.
class PeakDetailWeatherCard extends StatelessWidget {
  const PeakDetailWeatherCard({
    super.key,
    required this.forecast,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryTap,
    required this.expandedDay,
    required this.expandedHourly,
    required this.isExpandedHourlyLoading,
    required this.expandedHourlyError,
    required this.onDayTap,
    required this.onHourlyRetryTap,
  });

  // Aquestes dades defineixen l’estat principal de la previsió diària.
  // Permeten mostrar càrrega, error, dades disponibles o estat buit.
  final PeakWeather? forecast;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetryTap;

  // Aquestes dades controlen el panell horari del dia seleccionat.
  // Permeten carregar, mostrar o reintentar la previsió per hores d’un dia concret.
  final String? expandedDay;
  final PeakHourlyWeather? expandedHourly;
  final bool isExpandedHourlyLoading;
  final String? expandedHourlyError;
  final void Function(String date) onDayTap;
  final Future<void> Function(String date) onHourlyRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  // Aquest mètode construeix la capçalera de la targeta.
  // Mostra el títol i el nombre de dies disponibles quan ja hi ha previsió carregada.
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Text(
            'Previsió meteorològica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212B),
            ),
          ),
        ),
        if (_subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            _subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  // Aquest getter genera el subtítol amb el nombre real de dies retornats.
  String? get _subtitle {
    final days = forecast?.days.length;
    if (days == null) {
      return null;
    }
    return days == 1 ? '1 dia' : '$days dies';
  }

  // Aquest mètode decideix quin contingut mostrar segons l’estat actual.
  // Prioritza errors sense dades, càrrega inicial, estat buit i previsió disponible.
  Widget _buildBody() {
    final currentForecast = forecast;

    if (errorMessage != null &&
        (currentForecast == null || currentForecast.isEmpty)) {
      return _WeatherErrorState(
        message: errorMessage!,
        onRetryTap: onRetryTap,
      );
    }

    if (currentForecast == null) {
      return const _WeatherSkeleton();
    }

    if (currentForecast.isEmpty) {
      return const _WeatherEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: currentForecast.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final day = currentForecast.days[index];
              final isExpanded = expandedDay == day.date;
              return _DayPill(
                day: day,
                isToday: index == 0,
                isExpanded: isExpanded,
                onTap: () => onDayTap(day.date),
              );
            },
          ),
        ),
        // Aquesta animació mostra o amaga el panell horari de manera suau.
        // Evita salts visuals quan l’usuari obre o tanca un dia del carrusel.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expandedDay == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _HourlyPanel(
                    date: expandedDay!,
                    dayLabel: _fullDayLabelFor(expandedDay!),
                    hourly: expandedHourly,
                    isLoading: isExpandedHourlyLoading,
                    errorMessage: expandedHourlyError,
                    onRetryTap: () => onHourlyRetryTap(expandedDay!),
                  ),
                ),
        ),
      ],
    );
  }
}

// Aquest widget representa un dia dins del carrusel meteorològic.
// Mostra etiqueta, número del dia, condició dominant, temperatures i avís de vent.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.isToday,
    required this.isExpanded,
    required this.onTap,
  });

  final DailyForecast day;
  final bool isToday;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type =
        day.dominantCondition?.normalized ?? WeatherConditionType.unknown;
    final accent = weatherAccentColorFor(type);

    final background = isExpanded
        ? accent.withValues(alpha: 0.22)
        : isToday
            ? accent.withValues(alpha: 0.14)
            : const Color(0xFFF5F7FB);
    final borderColor = isExpanded
        ? accent
        : isToday
            ? accent.withValues(alpha: 0.4)
            : null;

    final windBlock = day.daytime ?? day.nighttime;
    final windSeverity = windSeverityFor(
      speedKmh: windBlock?.windSpeedKmh,
      gustKmh: windBlock?.windGustKmh,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 78,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: borderColor != null
                ? Border.all(
                    color: borderColor,
                    width: isExpanded ? 1.6 : 1.2,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    _dayLabelFor(day.date, isToday),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dayNumberFor(day.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17212B),
                    ),
                  ),
                ],
              ),
              weatherIconWidget(
                type,
                size: 28,
                color: accent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTemp(day.maxTempC),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17212B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTemp(day.minTempC),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              _DayWindLine(severity: windSeverity),
            ],
          ),
        ),
      ),
    );
  }
}

// Aquest widget mostra l’indicador de vent dins del dia.
// Reserva l’espai encara que no hi hagi vent destacable per mantenir el carrusel uniforme.
class _DayWindLine extends StatelessWidget {
  const _DayWindLine({required this.severity});

  final WindSeverity severity;

  @override
  Widget build(BuildContext context) {
    if (!severity.shouldHighlight) {
      return const SizedBox(height: 16);
    }
    final color = windSeverityColor(severity);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.air,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                severity.shortLabel,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest widget mostra la previsió horària del dia seleccionat.
// Pot representar càrrega, error, estat buit o hores disponibles.
class _HourlyPanel extends StatelessWidget {
  const _HourlyPanel({
    required this.date,
    required this.dayLabel,
    required this.hourly,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryTap,
  });

  final String date;

  // Aquesta etiqueta identifica el dia desplegat de manera llegible.
  final String dayLabel;
  final PeakHourlyWeather? hourly;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Previsió per hores',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              if (dayLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '· $dayLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildBody(),
        ],
      ),
    );
  }

  // Aquest mètode decideix el contingut del panell horari.
  // Si ja hi ha hores carregades, les conserva encara que un reintent falli.
  Widget _buildBody() {
    final currentHourly = hourly;

    if (errorMessage != null &&
        (currentHourly == null || currentHourly.isEmpty)) {
      return _HourlyErrorState(
        message: errorMessage!,
        onRetryTap: onRetryTap,
      );
    }

    if (currentHourly == null) {
      return const _HourlySkeleton();
    }

    if (currentHourly.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'No hi ha dades horàries disponibles per a aquest dia.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: currentHourly.hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _HourlyPill(hour: currentHourly.hours[index]);
        },
      ),
    );
  }
}

// Aquest widget representa una hora concreta dins del panell horari.
// Resumeix hora, condició, temperatura, precipitació i vent en un espai compacte.
class _HourlyPill extends StatelessWidget {
  const _HourlyPill({required this.hour});

  final HourlyForecast hour;

  @override
  Widget build(BuildContext context) {
    final type = hour.condition?.normalized ?? WeatherConditionType.unknown;
    final accent = weatherAccentColorFor(type);
    final precipPct = hour.precipProbabilityPct;
    final windSeverity = windSeverityFor(
      speedKmh: hour.windSpeedKmh,
      gustKmh: hour.windGustKmh,
    );

    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatHour(hour),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          weatherIconWidget(
            type,
            size: 22,
            color: accent,
            isDaytime: hour.isDaytime ?? true,
          ),
          Text(
            _formatTemp(hour.temperatureC),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212B),
            ),
          ),
          _HourlyFooter(
            precipPct: precipPct,
            windSeverity: windSeverity,
            windSpeedKmh: hour.windSpeedKmh,
          ),
        ],
      ),
    );
  }
}

// Aquest widget mostra la informació inferior d’una hora.
// Combina precipitació i vent sense duplicar aquesta lògica dins de cada element horari.
class _HourlyFooter extends StatelessWidget {
  const _HourlyFooter({
    required this.precipPct,
    required this.windSeverity,
    required this.windSpeedKmh,
  });

  final int precipPct;
  final WindSeverity windSeverity;
  final double? windSpeedKmh;

  @override
  Widget build(BuildContext context) {
    final hasPrecip = precipPct > 0;
    final hasWind = windSeverity.shouldHighlight;

    if (!hasPrecip && !hasWind) {
      return const SizedBox(height: 14);
    }

    final windColor = windSeverityColor(windSeverity);
    final children = <Widget>[];

    if (hasPrecip) {
      children.add(
        Text(
          '$precipPct%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: weatherAccentColorFor(WeatherConditionType.rainy),
          ),
        ),
      );
    }

    if (hasPrecip && hasWind) {
      children.add(const SizedBox(width: 4));
    }

    if (hasWind) {
      children.add(
        Icon(
          Symbols.air,
          size: 12,
          color: windColor,
        ),
      );
      if (!hasPrecip && windSpeedKmh != null) {
        children.add(const SizedBox(width: 2));
        children.add(
          Text(
            '${windSpeedKmh!.round()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: windColor,
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

// Aquest widget representa l’estat de càrrega del panell horari.
// Mostra elements de reserva perquè la mida del panell es mantingui estable.
class _HourlySkeleton extends StatelessWidget {
  const _HourlySkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// Aquest widget mostra un error del panell horari.
// Permet reintentar només la càrrega del dia seleccionat.
class _HourlyErrorState extends StatelessWidget {
  const _HourlyErrorState({
    required this.message,
    required this.onRetryTap,
  });

  final String message;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetryTap,
            child: const Text('Reintenta'),
          ),
        ],
      ),
    );
  }
}

// Aquest widget representa la càrrega inicial de la previsió diària.
// Manté la mida de la targeta mentre encara no hi ha dades.
class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 78,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF1F6),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// Aquest widget mostra un estat sense dades meteorològiques.
// S’utilitza quan la petició funciona però el backend no retorna previsió disponible.
class _WeatherEmptyState extends StatelessWidget {
  const _WeatherEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Encara no hi ha previsió disponible per a aquest cim.',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

// Aquest widget mostra l’error de càrrega de la previsió diària.
// Inclou una acció per tornar a intentar la consulta.
class _WeatherErrorState extends StatelessWidget {
  const _WeatherErrorState({
    required this.message,
    required this.onRetryTap,
  });

  final String message;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetryTap,
            child: const Text('Reintenta'),
          ),
        ],
      ),
    );
  }
}

// Aquest mètode transforma una data ISO en una etiqueta curta en català.
// Marca el primer dia com a avui perquè sigui fàcil d’identificar.
String _dayLabelFor(String date, bool isToday) {
  if (isToday) {
    return 'AVUI';
  }
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return '';
  }
  const labels = ['DL', 'DM', 'DX', 'DJ', 'DV', 'DS', 'DG'];
  final index = parsed.weekday - 1;
  if (index < 0 || index >= labels.length) {
    return '';
  }
  return labels[index];
}

// Aquest mètode crea una etiqueta natural per al dia del panell horari.
// Retorna Avui, Demà o el nom del dia amb el número corresponent.
String _fullDayLabelFor(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return date;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalized = DateTime(parsed.year, parsed.month, parsed.day);
  final diff = normalized.difference(today).inDays;
  if (diff == 0) return 'Avui';
  if (diff == 1) return 'Demà';
  const labels = [
    'Dilluns',
    'Dimarts',
    'Dimecres',
    'Dijous',
    'Divendres',
    'Dissabte',
    'Diumenge',
  ];
  final index = parsed.weekday - 1;
  if (index < 0 || index >= labels.length) {
    return date;
  }
  return '${labels[index]} ${parsed.day}';
}

// Aquest mètode extreu el dia del mes d’una data ISO.
// Si la data no és vàlida, retorna una cadena buida.
String _dayNumberFor(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return '';
  }
  return parsed.day.toString();
}

// Aquest mètode formata una temperatura en graus.
// Si no hi ha dada, retorna un guió per mantenir estable el component.
String _formatTemp(double? celsius) {
  if (celsius == null) {
    return '—';
  }
  return '${celsius.round()}°';
}

// Aquest mètode formata l’hora local d’una previsió horària.
// Si no es pot determinar l’hora, retorna una cadena buida.
String _formatHour(HourlyForecast hour) {
  final h = hour.hourOfDay;
  if (h == null) {
    return '';
  }
  return '${h.toString().padLeft(2, '0')}h';
}