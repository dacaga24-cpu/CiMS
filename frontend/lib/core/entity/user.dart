// Aquesta classe representa un usuari dins de l’aplicació.
// Agrupa les dades principals del compte i permet treballar amb aquesta informació
// de manera clara i consistent a diferents parts del sistema.
class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Aquest bloc recull les dades bàsiques que identifiquen l’usuari
  // i l’estat general del seu compte dins de l’aplicació.
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Aquest constructor crea un objecte User a partir d’un conjunt de dades en format JSON.
  // És rellevant perquè permet convertir la resposta rebuda del backend
  // en un objecte que l’aplicació pugui utilitzar fàcilment.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      isActive: _parseIsActive(json['isActive']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Aquest mètode transforma l’usuari en un format JSON.
  // Això és útil quan les dades s’han d’enviar, guardar o reutilitzar
  // en un format compatible amb altres parts del sistema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Aquest mètode crea una nova còpia de l’usuari permetent canviar només alguns valors.
  // És rellevant quan es vol actualitzar una part de la informació
  // sense haver de reconstruir manualment tot l’objecte.
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Aquest mètode converteix el valor rebut de l’estat del compte en un booleà clar per a l’aplicació.
  // Això ajuda a interpretar correctament la informació encara que arribi en formats diferents.
  static bool _parseIsActive(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }
}