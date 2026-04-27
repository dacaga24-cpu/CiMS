// Aquesta entitat representa una ascensió registrada per l’usuari.
// Guarda la relació entre un cim, una data concreta i les notes personals
// que l’usuari vulgui conservar dins del seu historial.
class Ascent {
  const Ascent({
    required this.id,
    required this.userId,
    required this.peakId,
    required this.ascentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final int peakId;
  final DateTime ascentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Aquest constructor transforma la resposta del backend en un objecte Ascent.
  // El backend retorna els camps en snake_case, seguint els noms de la base de dades.
  factory Ascent.fromJson(Map<String, dynamic> json) {
    return Ascent(
      id: _parseInt(json['id'], 'id'),
      userId: _parseInt(json['user_id'], 'user_id'),
      peakId: _parseInt(json['peak_id'], 'peak_id'),
      ascentDate: _parseDateOnly(json['ascent_date'], 'ascent_date'),
      notes: _parseNullableString(json['notes']),
      createdAt: _parseDateTime(json['created_at'], 'created_at'),
      updatedAt: _parseDateTime(json['updated_at'], 'updated_at'),
    );
  }

  // Aquest getter indica si l’ascensió té notes útils per mostrar a la interfície.
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  static int _parseInt(dynamic value, String fieldName) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('El camp "$fieldName" no és vàlid');
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static DateTime _parseDateOnly(dynamic value, String fieldName) {
    if (value is String) {
      final datePart = value.length >= 10 ? value.substring(0, 10) : value;
      final parts = datePart.split('-');

      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);

        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    }

    throw FormatException('El camp "$fieldName" no és vàlid');
  }

  static DateTime _parseDateTime(dynamic value, String fieldName) {
    if (value is String) {
      return DateTime.parse(value);
    }

    throw FormatException('El camp "$fieldName" no és vàlid');
  }
}