// Aquesta classe representa una comarca dins del sistema.
// Agrupa la informació bàsica que l'aplicació necessita per mostrar
// a quines regions pertany un cim i per alimentar els filtres del catàleg.
class Region {
  const Region({
    required this.id,
    required this.name,
  });

  // Aquest bloc recull les dades principals que identifiquen una comarca
  // dins de les respostes que arriben del backend.
  final int id;
  final String name;

  // Aquest constructor crea un objecte Region a partir d'un conjunt de dades JSON.
  // És rellevant perquè permet convertir directament les respostes del backend
  // en objectes que l'aplicació pot utilitzar sense duplicar lògica a cada pantalla.
  factory Region.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    int? parsedId;

    if (idRaw is int) {
      parsedId = idRaw;
    } else if (idRaw is num) {
      parsedId = idRaw.toInt();
    } else if (idRaw is String) {
      parsedId = int.tryParse(idRaw);
    }

    if (parsedId == null) {
      throw const FormatException('L\'identificador de la comarca no és vàlid');
    }

    final name = json['name'];
    if (name is! String || name.isEmpty) {
      throw const FormatException('El nom de la comarca no és vàlid');
    }

    return Region(id: parsedId, name: name);
  }
}
