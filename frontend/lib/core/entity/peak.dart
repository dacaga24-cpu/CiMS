import 'package:cims/core/entity/region.dart';

// Aquesta entitat representa la informació d’un cim dins de l’aplicació.
// Es fa servir tant al catàleg com al detall, de manera que pot contenir
// dades bàsiques i també camps opcionals si el backend els retorna.
class Peak {
  const Peak({
    required this.id,
    required this.name,
    required this.altitude,
    required this.regions,
    this.description,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final int altitude;
  final List<Region> regions;
  final String? description;
  final double? latitude;
  final double? longitude;

  // Aquest constructor transforma la resposta del backend en un objecte Peak.
  // Pot llegir tant la versió resumida del catàleg com una versió més completa
  // per al detall, sense obligar a crear una entitat diferent.
  factory Peak.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final altitudeRaw = json['altitude'];

    int? parsedId;
    int? parsedAltitude;

    if (idRaw is int) {
      parsedId = idRaw;
    } else if (idRaw is num) {
      parsedId = idRaw.toInt();
    } else if (idRaw is String) {
      parsedId = int.tryParse(idRaw);
    }

    if (altitudeRaw is int) {
      parsedAltitude = altitudeRaw;
    } else if (altitudeRaw is num) {
      parsedAltitude = altitudeRaw.toInt();
    } else if (altitudeRaw is String) {
      parsedAltitude = int.tryParse(altitudeRaw);
    }

    if (parsedId == null) {
      throw const FormatException('L\'identificador del cim no és vàlid');
    }

    final rawName = json['name']?.toString().trim();
    if (rawName == null || rawName.isEmpty) {
      throw const FormatException('El nom del cim no és vàlid');
    }

    if (parsedAltitude == null) {
      throw const FormatException('L\'altitud del cim no és vàlida');
    }

    final regionsRaw = json['regions'];
    final regions = <Region>[];

    if (regionsRaw is List) {
      for (final item in regionsRaw) {
        if (item is Map<String, dynamic>) {
          regions.add(Region.fromJson(item));
        }
      }
    }

    return Peak(
      id: parsedId,
      name: rawName,
      altitude: parsedAltitude,
      regions: regions,
      description: _parseNullableString(json['description']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  // Aquest getter prepara el text de regions en un únic format llegible.
  String get formattedRegions =>
      regions.map((region) => region.name).join(', ');

  // Aquest getter ajuda la vista a decidir si cal mostrar la descripció.
  bool get hasDescription =>
      description != null && description!.trim().isNotEmpty;

  // Aquest getter indica si el cim disposa de coordenades útils
  // per poder obrir la seva posició al mapa. La validació de rang
  // evita que un valor corrupte a la BD (per exemple un overflow del
  // DECIMAL) faci que el càlcul de límits del mapa s'expandeixi a tot
  // el planeta i deixi la càmera enfocada al pol nord.
  bool get hasMapPosition {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) {
      return false;
    }
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
