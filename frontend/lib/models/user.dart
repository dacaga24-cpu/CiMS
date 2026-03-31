// user.dart
// Responsabilidad: Modelo de datos del usuario.
// Solo estructura de datos: constructor, fromJson, toJson.
// NO contiene lógica de negocio.

class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Crea una instancia de User a partir de un Map JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // TODO: Implementar deserialización
    throw UnimplementedError();
  }

  // Convierte la instancia a un Map JSON
  Map<String, dynamic> toJson() {
    // TODO: Implementar serialización
    throw UnimplementedError();
  }
}
