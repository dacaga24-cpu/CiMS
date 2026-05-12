import 'package:cims/core/entity/weather_condition.dart';

// Aquest fitxer modela la previsió diària d'un cim tal com la retorna el
// backend de CiMS. La pantalla de detall l'utilitza per pintar la card de
// previsió i, en el futur, per derivar l'estat horari d'un dia concret.

// Aquesta entitat agrupa la previsió diürna o nocturna d'un dia. Es manté
// independent del dia perquè dia i nit poden tenir condicions diferents
// (matí soleat i nit núvol, per exemple) i la UI vol pintar tots dos
// estats per separat. Algunes hores poden no portar previsió i el camp
// arriba a null des del backend.
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

  // Aquesta propietat és la condició dominant del bloc.
  // Es manté opcional per acceptar dies on Google no la retorna.
  final WeatherCondition? condition;

  // Aquest bloc descriu la quantitat i la probabilitat de precipitació
  // per al bloc horari. Es guarden en percentatge i mil·límetres perquè
  // siguin coherents amb les unitats que retorna Google.
  final int precipProbabilityPct;
  final double precipQuantityMm;
  final int thunderstormProbabilityPct;

  // Aquest bloc descriu el vent: velocitat, ràfega i direcció. Tots són
  // opcionals perquè la previsió a llarg termini pot no incloure'ls.
  final double? windSpeedKmh;
  final double? windGustKmh;
  final int? windDirectionDegrees;

  // Aquest bloc descriu paràmetres secundaris útils per a la planificació
  // de muntanya: cobertura de núvols i índex UV. Es deixen nullables per
  // tolerar absències sense forçar valors per defecte enganyosos.
  final int? cloudCoverPct;
  final int? uvIndex;

  // Aquest constructor transforma una entrada de daytimeForecast o
  // nighttimeForecast del backend en una entitat tipada. Els camps que
  // no arriben es tracten com a "zero" o "no disponible" segons sigui més
  // útil per a la UI.
  factory HalfDayForecast.fromJson(Map<String, dynamic> json) {
    return HalfDayForecast(
      condition: WeatherCondition.fromNullableJson(json['condition']),
      precipProbabilityPct: _parseInt(json['precipProbabilityPct']),
      precipQuantityMm: _parseDouble(json['precipQuantityMm']),
      thunderstormProbabilityPct:
          _parseInt(json['thunderstormProbabilityPct']),
      windSpeedKmh: _parseNullableDouble(json['windSpeedKmh']),
      windGustKmh: _parseNullableDouble(json['windGustKmh']),
      windDirectionDegrees: _parseNullableInt(json['windDirectionDegrees']),
      cloudCoverPct: _parseNullableInt(json['cloudCoverPct']),
      uvIndex: _parseNullableInt(json['uvIndex']),
    );
  }

  // Aquest mètode tolera que el backend ometi el bloc sencer per a dies
  // on no hi ha dades. Sense aquest helper, la card hauria de validar el
  // camp abans de cridar fromJson cada vegada.
  static HalfDayForecast? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return HalfDayForecast.fromJson(value);
    }
    if (value is Map) {
      return HalfDayForecast.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
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
}

// Aquesta entitat representa la previsió d'un dia concret per a un cim
// (o una comarca, quan es consulta el resum regional). Agrupa
// temperatures mínima i màxima, els blocs diürn i nocturn i les hores
// d'eixida i posta de sol. La data arriba normalitzada com a YYYY-MM-DD
// per facilitar comparacions amb el dia que selecciona l'usuari.
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

  // Aquesta propietat és la data del dia en format ISO YYYY-MM-DD,
  // tal com l'emet el backend a partir de displayDate de Google.
  final String date;

  // Aquestes propietats són les temperatures extremes del dia en Celsius.
  // Es deixen opcionals per tolerar respostes parcials sense forçar el
  // valor 0 que confondria l'usuari.
  final double? minTempC;
  final double? maxTempC;
  final double? feelsLikeMinC;
  final double? feelsLikeMaxC;

  // Aquests blocs porten la previsió diürna i nocturna del dia.
  final HalfDayForecast? daytime;
  final HalfDayForecast? nighttime;

  // Aquestes propietats són les hores d'eixida i posta de sol en format
  // ISO 8601 amb timezone, tal com les emet Google.
  final String? sunriseTime;
  final String? sunsetTime;

  // Aquest getter retorna la condició dominant del dia (la diürna si
  // existeix, o la nocturna com a fallback). És el que pinta la card del
  // detall per resumir el dia sencer en una sola icona.
  WeatherCondition? get dominantCondition =>
      daytime?.condition ?? nighttime?.condition;

  // Aquest constructor transforma un dia de la resposta del backend en
  // una entitat tipada. Es manté el constructor sense paràmetres
  // obligatoris excepte la data, perquè qualsevol altra dada pot faltar
  // en previsions a llarg termini.
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

// Aquesta entitat agrupa la previsió completa retornada per
// l'endpoint /api/peaks/:peakId/weather/daily. Conserva el fus horari
// retornat per Google perquè la UI pugui mostrar correctament hores
// (eixida/posta de sol) i agrupacions per dia local.
class PeakWeather {
  const PeakWeather({
    required this.peakId,
    required this.days,
    this.timeZone,
  });

  // Aquesta propietat identifica el cim al qual pertany la previsió.
  // El backend l'inclou per facilitar diagnòstics i per si en algun moment
  // un consumidor vol detectar respostes obsoletes comparant el peakId
  // entrant amb el cim actual — avui per avui no es comprova, però el
  // camp queda disponible.
  final int peakId;

  // Aquesta propietat porta la previsió dia a dia ordenada cronològicament.
  final List<DailyForecast> days;

  // Aquesta propietat és el fus horari IANA retornat per Google.
  // La UI el deixa al controller per si vol formatar dates en local.
  final String? timeZone;

  // Aquest getter indica si la previsió arriba buida.
  // Permet pintar un estat "sense dades" sense barrejar-lo amb error.
  bool get isEmpty => days.isEmpty;

  factory PeakWeather.fromJson(Map<String, dynamic> json) {
    return PeakWeather(
      peakId: _parseInt(json['peakId']),
      timeZone: _parseNullableString(json['timeZone']),
      days: _parseDays(json['days']),
    );
  }

  static List<DailyForecast> _parseDays(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => DailyForecast.fromJson(Map<String, dynamic>.from(item)))
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
