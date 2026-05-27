// Aquesta classe representa un usuari dins de l’aplicació.
// Agrupa les dades principals del compte per utilitzar-les de manera coherent.
class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profilePhotoUrl,
  });

  // Aquestes dades identifiquen l’usuari i l’estat del seu compte.
  // També inclouen la foto de perfil quan està disponible.
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePhotoUrl;

  // Aquest constructor transforma la resposta del backend en un objecte User.
  // Accepta camps en diferents formats per adaptar-se al contracte de l’API.
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
      profilePhotoUrl: _readOptionalString(
        json,
        camelKey: 'profilePhotoUrl',
        snakeKey: 'profile_photo_url',
      ),
    );
  }

  // Aquest mètode transforma l’usuari en format JSON.
  // Permet reutilitzar les dades en altres parts del sistema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  // Aquest mètode crea una còpia de l’usuari canviant només els camps indicats.
  // És útil quan s’actualitza una part del perfil sense reconstruir tot l’objecte.
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePhotoUrl,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  // Aquest mètode interpreta l’estat del compte com un booleà.
  // Permet llegir el valor encara que arribi amb formats diferents.
  static bool _parseIsActive(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  // Aquest mètode llegeix un camp de text obligatori.
  // Accepta noms en camelCase i snake_case segons la resposta del backend.
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

  // Aquest mètode llegeix un camp de text opcional.
  // S’utilitza per dades que poden no existir encara, com la foto de perfil.
  static String? _readOptionalString(
    Map<String, dynamic> json, {
    required String camelKey,
    required String snakeKey,
  }) {
    final value = json[camelKey] ?? json[snakeKey];

    if (value is String && value.isNotEmpty) {
      return value;
    }

    return null;
  }

  // Aquest mètode converteix l’identificador rebut en un enter vàlid.
  // Si el valor no és correcte, evita crear un usuari amb dades inconsistents.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw const FormatException('L\'identificador d\'usuari no és vàlid');
  }

  // Aquest mètode transforma una data rebuda del backend en un DateTime.
  // Permet treballar amb dates de creació i actualització dins de l’aplicació.
  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    }

    throw const FormatException('La data rebuda no és vàlida');
  }
}