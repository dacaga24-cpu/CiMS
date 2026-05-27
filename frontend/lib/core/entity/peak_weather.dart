import 'package:cims/core/entity/weather_condition.dart';

// Aquest fitxer modela la previsió diària d’un cim.
// Permet mostrar el resum meteorològic dins de la pantalla de detall.

// Aquesta entitat agrupa la previsió d’una part del dia.
// Permet diferenciar les condicions diürnes i nocturnes d’una mateixa jornada.
class HalfDayForecast {
  const HalfDayForecast({
    this.condition,
    required this.precipProbabilityPct,
    required this.precipQuantityMm,
    required this.thunderstormProbabilityPct,
    this.windSpeedKmh,
    this.windGustKmh,
    this.windDirectionDegrees,
    this.cloudCoverPct,
    this.uvIndex,
  });

  // Aquesta propietat indica la condició meteorològica principal del bloc.
  // Es manté opcional perquè pot no estar disponible en totes les previsions.
  final WeatherCondition? condition;

  // Aquestes dades descriuen la probabilitat i quantitat de precipitació.
  // Ajuden l’usuari a valorar si les condicions són adequades per sortir a muntanya.
  final int precipProbabilityPct;
  final double precipQuantityMm;
  final int thunderstormProbabilityPct;

  // Aquestes dades descriuen la velocitat, la ràfega i la direcció del vent.
  // Són opcionals perquè el proveïdor pot no retornar-les en tots els casos.
  final double? windSpeedKmh;
  final double? windGustKmh;
  final int? windDirectionDegrees;

  // Aquestes dades complementàries aporten context sobre núvols i radiació solar.
  // Són útils per planificar millor l’activitat.
  final int? cloudCoverPct;
  final int? uvIndex;

  // Aquest constructor transforma la resposta del backend en una previsió de mig dia.
  // Els camps absents es tracten amb valors segurs o com a no disponibles.
  factory HalfDayForecast.fromJson(Map<String, dynamic> json) {
    return HalfDayForecast(
      condition: WeatherCondition.fromNullableJson(json['condition']),
      precipProbabilityPct: _parseInt(json['precipProbabilityPct']),
      precipQuantityMm: _parseDouble(json['precipQuantityMm']),
      thunderstormProbabilityPct: _parseInt(json['thunderstormProbabilityPct']),
      windSpeedKmh: _parseNullableDouble(json['windSpeedKmh']),
      windGustKmh: _parseNullableDouble(json['windGustKmh']),
      windDirectionDegrees: _parseNullableInt(json['windDirectionDegrees']),
      cloudCoverPct: _parseNullableInt(json['cloudCoverPct']),
      uvIndex: _parseNullableInt(json['uvIndex']),
    );
  }

  // Aquest mètode crea una previsió només si el bloc existeix.
  // Evita que la interfície hagi de comprovar manualment si hi ha dades.
  static HalfDayForecast? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return HalfDayForecast.fromJson(value);
    }
    if (value is Map) {
      return HalfDayForecast.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  // Aquestes funcions adapten valors del JSON a tipus segurs.
  // Permeten tolerar camps opcionals absents i aplicar valors per defecte quan cal.
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
}

// Aquesta entitat representa la previsió d’un dia concret per a un cim.
// Agrupa temperatures, previsió de dia i nit, i hores de sortida i posta de sol.
class DailyForecast {
  const DailyForecast({
    required this.date,
    this.minTempC,
    this.maxTempC,
    this.feelsLikeMinC,
    this.feelsLikeMaxC,
    this.daytime,
    this.nighttime,
    this.sunriseTime,
    this.sunsetTime,
  });

  // Aquesta propietat identifica el dia de la previsió.
  // Arriba en format YYYY-MM-DD per facilitar comparacions i seleccions.
  final String date;

  // Aquestes propietats indiquen les temperatures extremes del dia.
  // Es mantenen opcionals per no mostrar dades enganyoses si el backend no les envia.
  final double? minTempC;
  final double? maxTempC;
  final double? feelsLikeMinC;
  final double? feelsLikeMaxC;

  // Aquests blocs contenen la previsió diürna i nocturna del dia.
  final HalfDayForecast? daytime;
  final HalfDayForecast? nighttime;

  // Aquestes propietats indiquen l’hora de sortida i posta de sol.
  // Aporten context útil per planificar una activitat de muntanya.
  final String? sunriseTime;
  final String? sunsetTime;

  // Aquest getter retorna la condició principal del dia.
  // Prioritza la previsió diürna i utilitza la nocturna com a alternativa.
  WeatherCondition? get dominantCondition =>
      daytime?.condition ?? nighttime?.condition;

  // Aquest constructor transforma una previsió diària del backend en una entitat tipada.
  // Només la data és obligatòria perquè la resta de dades pot no estar disponible.
  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: (json['date']?.toString() ?? '').trim(),
      minTempC: _parseNullableDouble(json['minTempC']),
      maxTempC: _parseNullableDouble(json['maxTempC']),
      feelsLikeMinC: _parseNullableDouble(json['feelsLikeMinC']),
      feelsLikeMaxC: _parseNullableDouble(json['feelsLikeMaxC']),
      daytime: HalfDayForecast.fromNullableJson(json['daytime']),
      nighttime: HalfDayForecast.fromNullableJson(json['nighttime']),
      sunriseTime: _parseNullableString(json['sunriseTime']),
      sunsetTime: _parseNullableString(json['sunsetTime']),
    );
  }

  // Aquestes funcions adapten valors opcionals del JSON.
  // Permeten construir el model encara que alguns camps no arribin informats.
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

// Aquesta entitat agrupa la previsió completa d’un cim.
// Conserva el cim, el fus horari i la llista de dies disponibles.
class PeakWeather {
  const PeakWeather({
    required this.peakId,
    required this.days,
    this.timeZone,
  });

  // Aquesta propietat identifica el cim al qual pertany la previsió.
  final int peakId;

  // Aquesta propietat conté la previsió dia a dia ordenada cronològicament.
  final List<DailyForecast> days;

  // Aquesta propietat indica el fus horari de la previsió.
  // Pot ser útil per mostrar hores locals de manera coherent.
  final String? timeZone;

  // Aquest getter indica si la previsió arriba buida.
  // Permet mostrar un estat sense dades sense confondre’l amb un error.
  bool get isEmpty => days.isEmpty;

  // Aquest constructor transforma la resposta del backend en una previsió completa.
  // Si la llista de dies no és vàlida, retorna una col·lecció buida.
  factory PeakWeather.fromJson(Map<String, dynamic> json) {
    return PeakWeather(
      peakId: _parseInt(json['peakId']),
      timeZone: _parseNullableString(json['timeZone']),
      days: _parseDays(json['days']),
    );
  }

  // Aquesta funció adapta la llista de dies rebuda del backend.
  // Només conserva els elements que tenen el format necessari per crear previsions diàries.
  static List<DailyForecast> _parseDays(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => DailyForecast.fromJson(Map<String, dynamic>.from(item)))
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