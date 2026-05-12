import 'package:cims/core/entity/weather_condition.dart';

// Aquest fitxer modela la previsió horària d'un cim per a un dia concret,
// tal com la retorna l'endpoint /api/peaks/:peakId/weather/hourly. La
// pantalla de detall l'utilitza per pintar el panell que es desplega
// quan l'usuari toca una píldora de dia.

// Aquesta entitat representa una hora concreta dins la previsió. Conté
// totes les mètriques que ofereix Google excepte la humitat (decisió de
// producte) i agrupa la condició dins de WeatherCondition perquè la UI
// pugui pintar icones consistents amb la card diària.
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

  // startTime és la marca temporal UTC retornada per Google.
  // localDateTime és la mateixa hora ja serialitzada al fus del cim
  // (cadena ISO sense Z). La UI agrupa les hores per dia local llegint
  // localDateTime, evitant haver de convertir zones horàries
  // manualment al client.
  final String? startTime;
  final String? localDateTime;

  // Indica si l'hora es considera diürna segons Google. Permet a la UI
  // diferenciar visualment dia i nit dins del mateix panell horari.
  final bool? isDaytime;

  // Temperatures de l'hora en graus Celsius.
  final double? temperatureC;
  final double? feelsLikeC;

  // Condició dominant per a l'hora (icona + categoria normalitzada).
  final WeatherCondition? condition;

  // Bloc de precipitació: probabilitat (%) i quantitat (mm).
  final int precipProbabilityPct;
  final double precipQuantityMm;
  final int thunderstormProbabilityPct;

  // Bloc de vent: velocitat, ràfega i direcció.
  final double? windSpeedKmh;
  final double? windGustKmh;
  final int? windDirectionDegrees;

  // Paràmetres secundaris útils per a la planificació de muntanya.
  final int? cloudCoverPct;
  final int? uvIndex;
  final double? visibilityKm;
  final double? pressureMbar;

  // Aquest getter retorna l'hora del dia (0..23) extreta de
  // localDateTime. La UI l'usa per pintar l'etiqueta de cada hora sense
  // dependre de DateTime.parse, que es comporta diferent segons el fus
  // del dispositiu.
  int? get hourOfDay {
    final value = localDateTime;
    if (value == null || value.length < 13) {
      return null;
    }
    return int.tryParse(value.substring(11, 13));
  }

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

// Aquesta entitat agrupa la previsió horària retornada pel backend per
// a un cim i una data concrets. Conserva el fus horari per si la UI
// vol formatar hores amb context, i la data ISO per identificar
// inequívocament a quin dia pertany aquesta cache local.
class PeakHourlyWeather {
  const PeakHourlyWeather({
    required this.peakId,
    required this.date,
    required this.hours,
    this.timeZone,
  });

  final int peakId;

  // Cadena ISO YYYY-MM-DD del dia que el client va sol·licitar. Es
  // conserva al payload perquè la UI pugui mostrar el dia sense haver
  // de derivar-lo de la primera hora i, sobretot, per detectar
  // respostes obsoletes en cas que el controller introdueixi
  // comparacions futur (avui per avui no hi ha aquesta validació; la
  // cache del detall s'indexa pel paràmetre rebut al `_loadHourlyFor`).
  final String date;
  final String? timeZone;
  final List<HourlyForecast> hours;

  bool get isEmpty => hours.isEmpty;

  factory PeakHourlyWeather.fromJson(Map<String, dynamic> json) {
    return PeakHourlyWeather(
      peakId: _parseInt(json['peakId']),
      date: (json['date']?.toString() ?? '').trim(),
      timeZone: _parseNullableString(json['timeZone']),
      hours: _parseHours(json['hours']),
    );
  }

  static List<HourlyForecast> _parseHours(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => HourlyForecast.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

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
