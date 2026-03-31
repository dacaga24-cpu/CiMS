// region.dart
// Responsabilidad: Modelo de datos de una comarca.
// Solo estructura de datos: constructor, fromJson, toJson.
// NO contiene lógica de negocio.

class Region {
  final int? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Region({
    this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  // Crea una instancia de Region a partir de un Map JSON
  factory Region.fromJson(Map<String, dynamic> json) {
    // TODO: Implementar deserialización
    throw UnimplementedError();
  }

  // Convierte la instancia a un Map JSON
  Map<String, dynamic> toJson() {
    // TODO: Implementar serialización
    throw UnimplementedError();
  }
}
