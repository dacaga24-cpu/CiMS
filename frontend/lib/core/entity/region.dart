// Aquesta classe representa una comarca dins del sistema.
// S’utilitza per mostrar les regions dels cims i alimentar els filtres del catàleg.
class Region {
  const Region({
    required this.id,
    required this.name,
  });

  // Aquestes dades identifiquen una comarca dins de l’aplicació.
  // Permeten mostrar-la i relacionar-la amb els cims del catàleg.
  final int id;
  final String name;

  // Aquest constructor transforma la resposta del backend en una comarca.
  // Valida que l’identificador i el nom siguin correctes abans de crear l’objecte.
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