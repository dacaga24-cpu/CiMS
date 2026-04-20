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
    id: _parseInt(json['id']),
    firstName: _readString(
      json,
      camelKey: 'firstName',
      snakeKey: 'first_name',
    ),
    lastName: _readString(
      json,
      camelKey: 'lastName',
      snakeKey: 'last_name',
    ),
    email: _readString(
      json,
      camelKey: 'email',
      snakeKey: 'email',
    ),
    isActive: _parseIsActive(
      json['isActive'] ?? json['is_active'],
    ),
    createdAt: _parseDateTime(
      json['createdAt'] ?? json['created_at'],
    ),
    updatedAt: _parseDateTime(
      json['updatedAt'] ?? json['updated_at'],
    ),
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

  // Aquest mètode llegeix un camp de text acceptant tant el nom en camelCase
  // com en snake_case, per adaptar-se millor a diferents respostes del backend.
  static String _readString(
  Map<String, dynamic> json, {
  required String camelKey,
  required String snakeKey,
}) {
  final value = json[camelKey] ?? json[snakeKey];

  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException(
    'El camp "$camelKey/$snakeKey" no és vàlid',
  );
}

  // Aquest mètode intenta convertir un valor rebut a enter
  // per assegurar que l’identificador de l’usuari tingui un format vàlid.
  static int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }

  throw const FormatException('L\'identificador d\'usuari no és vàlid');
}

  // Aquest mètode transforma el valor rebut en una data usable per l’aplicació.
  // És important perquè les dades temporals del backend acostumen a arribar en format text.
  static DateTime _parseDateTime(dynamic value) {
  if (value is String) {
    return DateTime.parse(value);
  }

  throw const FormatException('La data rebuda no és vàlida');
}
}