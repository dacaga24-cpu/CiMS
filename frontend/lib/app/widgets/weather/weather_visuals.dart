import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// Aquest fitxer centralitza els recursos visuals de la meteorologia.
// Manté icones, colors i nivells de vent coherents en totes les pantalles.
const Color _weatherSunColor = Color(0xFFF59E0B);
const Color _weatherMoonColor = Color(0xFFCBD5E1);

// Aquest mètode retorna la icona visual d’una condició meteorològica.
// Adapta el dibuix segons si és de dia o de nit quan la condició ho requereix.
Widget weatherIconWidget(
  WeatherConditionType type, {
  required double size,
  required Color color,
  bool isDaytime = true,
}) {
  switch (type) {
    case WeatherConditionType.sunny:
      return Icon(
        isDaytime ? Symbols.sunny : Symbols.bedtime,
        size: size,
        color: isDaytime ? _weatherSunColor : _weatherMoonColor,
      );
    case WeatherConditionType.partlyCloudy:
      return _PartlyCloudyIcon(
        size: size,
        cloudColor: color,
        isDaytime: isDaytime,
      );
    case WeatherConditionType.cloudy:
      return Icon(Symbols.cloudy, size: size, color: color);
    case WeatherConditionType.rainy:
      return Icon(Symbols.rainy, size: size, color: color);
    case WeatherConditionType.snowy:
      return Icon(Symbols.ac_unit, size: size, color: color);
    case WeatherConditionType.foggy:
      return Icon(Symbols.foggy, size: size, color: color);
    case WeatherConditionType.unknown:
      return Icon(Symbols.help_outline, size: size, color: color);
  }
}

// Aquest widget composa una icona de sol o lluna amb núvol.
// Permet representar el temps variable amb colors diferenciats.
class _PartlyCloudyIcon extends StatelessWidget {
  const _PartlyCloudyIcon({
    required this.size,
    required this.cloudColor,
    required this.isDaytime,
  });

  // Aquestes dades defineixen la mida i els colors de la composició.
  // També indiquen si s’ha de mostrar sol o lluna.
  final double size;
  final Color cloudColor;
  final bool isDaytime;

  @override
  Widget build(BuildContext context) {
    final celestialIcon = isDaytime ? Symbols.sunny : Symbols.bedtime;
    final celestialColor = isDaytime ? _weatherSunColor : _weatherMoonColor;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              celestialIcon,
              size: size * 0.62,
              color: celestialColor,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Icon(
              Symbols.cloud,
              size: size * 0.78,
              color: cloudColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest mètode retorna el color d’accent d’una condició meteorològica.
// S’utilitza perquè targetes, filtres i icones comparteixin la mateixa paleta.
Color weatherAccentColorFor(WeatherConditionType type) {
  switch (type) {
    case WeatherConditionType.sunny:
      return const Color(0xFFF59E0B);
    case WeatherConditionType.partlyCloudy:
      return const Color(0xFF9CA3AF);
    case WeatherConditionType.cloudy:
      return const Color(0xFF4B5563);
    case WeatherConditionType.rainy:
      return const Color(0xFF2563EB);
    case WeatherConditionType.snowy:
      return const Color(0xFF7DD3FC);
    case WeatherConditionType.foggy:
      return const Color(0xFF94A3B8);
    case WeatherConditionType.unknown:
      return const Color(0xFFCBD5E1);
  }
}

// Aquest enum classifica la intensitat del vent.
// Permet destacar només els casos que poden afectar una sortida de muntanya.
enum WindSeverity {
  calm,
  moderate,
  strong,
}

// Aquesta extensió aporta textos i criteris visuals als nivells de vent.
// Evita duplicar etiquetes en els widgets que mostren avisos o badges.
extension WindSeverityLabels on WindSeverity {
  // Indica si el nivell de vent s’ha de destacar visualment.
  bool get shouldHighlight => this != WindSeverity.calm;

  // Etiqueta completa del nivell de vent.
  // S’utilitza en espais on hi ha prou context visual.
  String get displayLabel {
    switch (this) {
      case WindSeverity.calm:
        return 'Calm';
      case WindSeverity.moderate:
        return 'Vent fort';
      case WindSeverity.strong:
        return 'Vent molt fort';
    }
  }

  // Etiqueta curta del nivell de vent.
  // S’utilitza en components amb poc espai disponible.
  String get shortLabel {
    switch (this) {
      case WindSeverity.calm:
        return '';
      case WindSeverity.moderate:
        return 'Fort';
      case WindSeverity.strong:
        return 'Molt fort';
    }
  }
}

// Aquest mètode classifica el vent segons velocitat sostinguda i ràfega.
// Ajuda a mostrar avisos útils per planificar una activitat de muntanya.
WindSeverity windSeverityFor({double? speedKmh, double? gustKmh}) {
  final speed = speedKmh ?? 0;
  final gust = gustKmh ?? 0;
  if (speed >= 40 || gust >= 60) {
    return WindSeverity.strong;
  }
  if (speed >= 20 || gust >= 40) {
    return WindSeverity.moderate;
  }
  return WindSeverity.calm;
}

// Aquest mètode retorna el color associat a cada nivell de vent.
// Manté una lectura visual coherent entre la previsió diària i l’horària.
Color windSeverityColor(WindSeverity severity) {
  switch (severity) {
    case WindSeverity.calm:
      return const Color(0xFF6B7280);
    case WindSeverity.moderate:
      return const Color(0xFFD97706);
    case WindSeverity.strong:
      return const Color(0xFFDC2626);
  }
}