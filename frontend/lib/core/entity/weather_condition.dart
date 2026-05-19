// Aquest fitxer modela la condició meteorològica retornada pel backend
// per a un cim o una comarca. Centralitza la traducció del tipus cru de
// Google a la categoria normalitzada que utilitzen tant la card de detall
// com el filtre per clima, perquè qualsevol pantalla que vulgui pintar el
// clima ho faci sempre amb la mateixa categorització.

// Aquest enum recull les sis condicions normalitzades exposades pel
// backend (sol, variable, nuvolós, pluja, neu, boira), més un valor
// desconegut per a tipus de Google que encara no estan mapats. La UI
// tracta UNKNOWN com a "no disponible" perquè no estigui obligada a
// triar una icona o color arbitrari quan apareix.
enum WeatherConditionType {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  snowy,
  foggy,
  unknown,
}

// Aquesta extensió permet llegir un identificador estable del tipus
// (el codi que envia el backend) i, a l'inrevés, parsejar una cadena
// rebuda per la xarxa o per query string en el valor d'enum corresponent.
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

  // Aquest getter retorna l'etiqueta visible en català per a aquesta
  // condició. Es manté aquí per evitar duplicar el text en cada widget
  // que vulgui mostrar la categoria (chip de filtre, card de detall,
  // resum de filtres actius).
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

// Aquest mètode tradueix una cadena de codi al valor enum corresponent.
// Si el codi no està definit, es retorna unknown perquè la UI mai trenqui
// per un nou tipus que Google pugui afegir sense avís.
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

// Aquesta entitat representa la condició meteorològica detallada que
// retorna Google per a un dia o una hora concreta. Conserva el tipus
// original (útil per a logs i diagnòstic) i el tipus normalitzat (útil
// per al filtre i per pintar icones). La descripció és el text traduït
// per Google que la card pot mostrar tal qual.
class WeatherCondition {
  const WeatherCondition({
    required this.normalized,
    this.rawType,
    this.description,
    this.iconBaseUri,
  });

  // Aquesta propietat indica a quin grup normalitzat pertany la condició.
  // És el camp que utilitzen els filtres i els colors de la UI.
  final WeatherConditionType normalized;

  // Aquesta propietat conserva el codi cru retornat per Google. Avui no
  // el consumeix cap pantalla — la card del detall pinta a partir de
  // normalized — però es preserva per facilitar diagnòstics quan
  // aparegui un tipus inesperat que caigui a UNKNOWN i calgui afegir-lo
  // al mapa del backend.
  final String? rawType;

  // Aquesta propietat porta la descripció textual traduïda per Google.
  // Es manté opcional perquè algunes hores poden no portar-la.
  final String? description;

  // Aquesta propietat és la URL base de la icona oficial de Google. Avui
  // la card del detall utilitza icones Material en lloc d'aquesta URL
  // (més ràpid, sense dependència de xarxa per a l'iconografia), però es
  // preserva perquè futures vistes la puguin aprofitar sense canviar el
  // contracte amb el backend.
  final String? iconBaseUri;

  // Aquest constructor transforma la resposta del backend en una entitat
  // utilitzable. Si arriba null o un valor amb format inesperat, es retorna
  // una condició unknown perquè la UI no es trenqui mai.
  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      normalized: parseWeatherConditionType(json['normalized']),
      rawType: _parseNullableString(json['type']),
      description: _parseNullableString(json['description']),
      iconBaseUri: _parseNullableString(json['iconBaseUri']),
    );
  }

  // Aquest mètode evita crear una condició buida quan el backend no envia
  // l'objecte (per exemple, una nit sense previsió disponible).
  static WeatherCondition? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return WeatherCondition.fromJson(value);
    }
    if (value is Map) {
      return WeatherCondition.fromJson(Map<String, dynamic>.from(value));
    }
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
