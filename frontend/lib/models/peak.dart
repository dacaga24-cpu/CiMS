// peak.dart
// Responsabilidad: Modelo de datos de un cim (pico).
// Solo estructura de datos: constructor, fromJson, toJson.
// NO contiene lógica de negocio.

class Peak {
  final int? id;
  final String name;
  final int altitude;
  final double latitude;
  final double longitude;
  final int regionId;
  final String? regionName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Peak({
    this.id,
    required this.name,
    required this.altitude,
    required this.latitude,
    required this.longitude,
    required this.regionId,
    this.regionName,
    this.createdAt,
    this.updatedAt,
  });

  // Crea una instancia de Peak a partir de un Map JSON
  factory Peak.fromJson(Map<String, dynamic> json) {
    // TODO: Implementar deserialización
    throw UnimplementedError();
  }

  // Convierte la instancia a un Map JSON
  Map<String, dynamic> toJson() {
    // TODO: Implementar serialización
    throw UnimplementedError();
  }
}
