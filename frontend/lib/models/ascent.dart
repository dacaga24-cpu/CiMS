// ascent.dart
// Responsabilidad: Modelo de datos de una ascensión.
// Solo estructura de datos: constructor, fromJson, toJson.
// NO contiene lógica de negocio.

class Ascent {
  final int? id;
  final int userId;
  final int peakId;
  final DateTime ascentDate;
  final String? notes;
  final String? peakName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ascent({
    this.id,
    required this.userId,
    required this.peakId,
    required this.ascentDate,
    this.notes,
    this.peakName,
    this.createdAt,
    this.updatedAt,
  });

  // Crea una instancia de Ascent a partir de un Map JSON
  factory Ascent.fromJson(Map<String, dynamic> json) {
    // TODO: Implementar deserialización
    throw UnimplementedError();
  }

  // Convierte la instancia a un Map JSON
  Map<String, dynamic> toJson() {
    // TODO: Implementar serialización
    throw UnimplementedError();
  }
}
