import 'package:cims/core/entity/weather_condition.dart';

// Aquest fitxer modela la previsió horària d’un cim.
// Permet mostrar el detall meteorològic d’un dia concret dins la pantalla del cim.

// Aquesta entitat representa una hora concreta dins la previsió.
// Agrupa les dades necessàries perquè la interfície mostri temperatura, vent, precipitació i estat del cel.
class HourlyForecast {
  const HourlyForecast({
    this.startTime,
    this.localDateTime,
    this.isDaytime,
    this.temperatureC,
    this.feelsLikeC,
    this.condition,
    required this.precipProbabilityPct,
    required this.precipQuantityMm,
    required this.thunderstormProbabilityPct,
    this.windSpeedKmh,
    this.windGustKmh,
    this.windDirectionDegrees,
    this.cloudCoverPct,
    this.uvIndex,
    this.visibilityKm,
    this.pressureMbar,
  });

  // Aquestes dades identifiquen l’hora de la previsió.
  // La interfície utilitza localDateTime per mostrar l’hora segons el dia local del cim.
  final String? startTime;
  final String? localDateTime;

  // Indica si la previsió correspon a una hora de dia o de nit.
  // Permet diferenciar visualment les franges horàries.
  final bool? isDaytime;

  // Temperatures de l’hora en graus Celsius.
  final double? temperatureC;
  final double? feelsLikeC;

  // Condició meteorològica principal de l’hora.
  // Inclou la categoria normalitzada que utilitza la interfície.
  final WeatherCondition? condition;

  // Aquest bloc resumeix la probabilitat i quantitat de precipitació.
  final int precipProbabilityPct;
  final double precipQuantityMm;
  final int thunderstormProbabilityPct;

  // Aquest bloc agrupa la informació principal del vent.
  final double? windSpeedKmh;
  final double? windGustKmh;
  final int? windDirectionDegrees;

  // Aquestes dades complementàries ajuden a valorar millor les condicions de muntanya.
  final int? cloudCoverPct;
  final int? uvIndex;
  final double? visibilityKm;
  final double? pressureMbar;

  // Aquest getter extreu l’hora del dia a partir de la data local.
  // Permet pintar etiquetes horàries sense dependre del fus horari del dispositiu.
  int? get hourOfDay {
    final value = localDateTime;
    if (value == null || value.length < 13) {
      return null;
    }
    return int.tryParse(value.substring(11, 13));
  }

  // Aquest constructor transforma la resposta del backend en una previsió horària.
  // Aplica conversions segures perquè la pantalla pugui treballar amb valors previsibles.
  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      startTime: _parseNullableString(json['startTime']),
      localDateTime: _parseNullableString(json['localDateTime']),
      isDaytime: json['isDaytime'] is bool ? json['isDaytime'] as bool : null,
      temperatureC: _parseNullableDouble(json['temperatureC']),
      feelsLikeC: _parseNullableDouble(json['feelsLikeC']),
      condition: WeatherCondition.fromNullableJson(json['condition']),
      precipProbabilityPct: _parseInt(json['precipProbabilityPct']),
      precipQuantityMm: _parseDouble(json['precipQuantityMm']),
      thunderstormProbabilityPct: _parseInt(json['thunderstormProbabilityPct']),
      windSpeedKmh: _parseNullableDouble(json['windSpeedKmh']),
      windGustKmh: _parseNullableDouble(json['windGustKmh']),
      windDirectionDegrees: _parseNullableInt(json['windDirectionDegrees']),
      cloudCoverPct: _parseNullableInt(json['cloudCoverPct']),
      uvIndex: _parseNullableInt(json['uvIndex']),
      visibilityKm: _parseNullableDouble(json['visibilityKm']),
      pressureMbar: _parseNullableDouble(json['pressureMbar']),
    );
  }

  // Aquestes funcions converteixen valors del JSON a tipus segurs.
  // Permeten tolerar camps opcionals absents i mantenir valors per defecte quan cal.
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

// Aquesta entitat agrupa la previsió horària d’un cim per a una data concreta.
// Conserva el cim, el dia consultat, el fus horari i la llista d’hores disponibles.
class PeakHourlyWeather {
  const PeakHourlyWeather({
    required this.peakId,
    required this.date,
    required this.hours,
    this.timeZone,
  });

  final int peakId;

  // Aquesta data identifica el dia de la previsió retornada.
  // Permet saber a quin dia correspon la llista d’hores carregada.
  final String date;
  final String? timeZone;
  final List<HourlyForecast> hours;

  bool get isEmpty => hours.isEmpty;

  // Aquest constructor transforma la resposta del backend en una previsió horària completa.
  // Si la llista d’hores no és vàlida, retorna una col·lecció buida.
  factory PeakHourlyWeather.fromJson(Map<String, dynamic> json) {
    return PeakHourlyWeather(
      peakId: _parseInt(json['peakId']),
      date: (json['date']?.toString() ?? '').trim(),
      timeZone: _parseNullableString(json['timeZone']),
      hours: _parseHours(json['hours']),
    );
  }

  // Aquesta funció adapta la llista d’hores rebuda del backend.
  // Només conserva els elements que tenen el format necessari per crear previsions horàries.
  static List<HourlyForecast> _parseHours(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => HourlyForecast.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Aquestes funcions converteixen valors simples del JSON a tipus segurs.
  // Permeten construir el model encara que algun camp opcional no arribi informat.
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}