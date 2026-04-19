class Peak {
  const Peak({
    required this.id,
    required this.name,
    required this.altitude,
    required this.regions,
  });

  // Aquesta entitat representa la informació mínima que necessita el catàleg
  // per mostrar un cim a la llista. Inclou l’identificador, el nom,
  // l’altitud i la col·lecció de regions associades.
  final int id;
  final String name;
  final int altitude;
  final List<String> regions;

  // Aquest getter prepara el text de regions en un únic format llegible.
  // És útil perquè la vista no hagi de decidir com unir la informació territorial.
  String get formattedRegions => regions.join(', ');
}
