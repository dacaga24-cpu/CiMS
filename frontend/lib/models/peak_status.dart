// peak_status.dart
// Responsabilidad: Modelo de datos del estado de un cim para un usuario.
// Solo estructura de datos: constructor, fromJson, toJson.
// NO contiene lógica de negocio.

class PeakStatus {
  final int? id;
  final int userId;
  final int peakId;
  final bool isCompleted;
  final bool isTarget;
  final bool isFavorite;
  final String? peakName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PeakStatus({
    this.id,
    required this.userId,
    required this.peakId,
    this.isCompleted = false,
    this.isTarget = false,
    this.isFavorite = false,
    this.peakName,
    this.createdAt,
    this.updatedAt,
  });

  // Crea una instancia de PeakStatus a partir de un Map JSON
  factory PeakStatus.fromJson(Map<String, dynamic> json) {
    // TODO: Implementar deserialización
    throw UnimplementedError();
  }

  // Convierte la instancia a un Map JSON
  Map<String, dynamic> toJson() {
    // TODO: Implementar serialización
    throw UnimplementedError();
  }
}
