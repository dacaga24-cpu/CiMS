// Aquest fitxer modela la condició meteorològica retornada pel backend.
// Centralitza les categories perquè totes les pantalles mostrin el clima amb el mateix criteri.

// Aquest enum recull les condicions meteorològiques normalitzades.
// Inclou un valor desconegut per evitar errors quan arriba un tipus no previst.
enum WeatherConditionType {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  snowy,
  foggy,
  unknown,
}

// Aquesta extensió associa cada condició amb el codi intern i l’etiqueta visible.
// Això evita duplicar textos i codis en diferents widgets.
extension WeatherConditionTypeCodec on WeatherConditionType {
  String get code {
    switch (this) {
      case WeatherConditionType.sunny:
        return 'SUNNY';
      case WeatherConditionType.partlyCloudy:
        return 'PARTLY_CLOUDY';
      case WeatherConditionType.cloudy:
        return 'CLOUDY';
      case WeatherConditionType.rainy:
        return 'RAINY';
      case WeatherConditionType.snowy:
        return 'SNOWY';
      case WeatherConditionType.foggy:
        return 'FOGGY';
      case WeatherConditionType.unknown:
        return 'UNKNOWN';
    }
  }

  // Aquest getter retorna l’etiqueta en català de cada condició.
  // S’utilitza per mostrar el clima en filtres, targetes i resums visuals.
  String get displayLabel {
    switch (this) {
      case WeatherConditionType.sunny:
        return 'Soleat';
      case WeatherConditionType.partlyCloudy:
        return 'Variable';
      case WeatherConditionType.cloudy:
        return 'Nuvolós';
      case WeatherConditionType.rainy:
        return 'Pluja';
      case WeatherConditionType.snowy:
        return 'Neu';
      case WeatherConditionType.foggy:
        return 'Boira';
      case WeatherConditionType.unknown:
        return 'Sense dades';
    }
  }
}

// Aquest mètode transforma un codi rebut en una condició normalitzada.
// Si el valor no és reconegut, retorna unknown perquè la interfície continuï funcionant.
WeatherConditionType parseWeatherConditionType(dynamic value) {
  if (value is String) {
    final upper = value.trim().toUpperCase();
    for (final type in WeatherConditionType.values) {
      if (type.code == upper) {
        return type;
      }
    }
  }
  return WeatherConditionType.unknown;
}

// Aquesta entitat representa una condició meteorològica concreta.
// Conserva la categoria normalitzada i informació complementària retornada pel backend.
class WeatherCondition {
  const WeatherCondition({
    required this.normalized,
    this.rawType,
    this.description,
    this.iconBaseUri,
  });

  // Aquesta propietat indica el grup normalitzat de la condició.
  // És el valor que utilitzen els filtres, colors i icones de la interfície.
  final WeatherConditionType normalized;

  // Aquesta propietat conserva el tipus original retornat pel proveïdor.
  // Pot ajudar a diagnosticar condicions noves o no classificades.
  final String? rawType;

  // Aquesta propietat conté la descripció textual de la condició.
  // Es manté opcional perquè pot no arribar en totes les previsions.
  final String? description;

  // Aquesta propietat conserva la URL base de la icona del proveïdor.
  // Queda disponible per a futures vistes que vulguin utilitzar-la.
  final String? iconBaseUri;

  // Aquest constructor transforma la resposta del backend en una condició meteorològica.
  // Si el tipus no és reconegut, la condició queda marcada com a desconeguda.
  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      normalized: parseWeatherConditionType(json['normalized']),
      rawType: _parseNullableString(json['type']),
      description: _parseNullableString(json['description']),
      iconBaseUri: _parseNullableString(json['iconBaseUri']),
    );
  }

  // Aquest mètode crea una condició només si el backend envia un objecte vàlid.
  // Permet tractar previsions sense condició disponible sense trencar la interfície.
  static WeatherCondition? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return WeatherCondition.fromJson(value);
    }
    if (value is Map) {
      return WeatherCondition.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  // Aquesta funció transforma textos opcionals del JSON.
  // Retorna null quan el valor no té contingut útil.
  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}