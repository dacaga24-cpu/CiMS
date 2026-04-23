import 'package:cims/core/entity/region.dart';

// Aquesta entitat representa la informació mínima que necessita el catàleg
// per mostrar un cim a la llista. Inclou l'identificador, el nom,
// l'altitud i la col·lecció de regions associades.
class Peak {
  const Peak({
    required this.id,
    required this.name,
    required this.altitude,
    required this.regions,
  });

  final int id;
  final String name;
  final int altitude;
  final List<Region> regions;

  // Aquest constructor transforma la resposta del backend en un objecte Peak.
  // Només llegeix els camps que el catàleg necessita en aquesta iteració,
  // deixant marge perquè el detall del cim creixi més endavant.
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

    final name = json['name'];
    if (name is! String || name.isEmpty) {
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
      name: name,
      altitude: parsedAltitude,
      regions: regions,
    );
  }

  // Aquest getter prepara el text de regions en un únic format llegible.
  // És útil perquè la vista no hagi de decidir com unir la informació territorial.
  String get formattedRegions => regions.map((region) => region.name).join(', ');
}
