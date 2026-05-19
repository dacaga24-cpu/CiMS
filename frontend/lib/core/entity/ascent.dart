import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/entity/ascent_verification.dart';

// Aquesta entitat representa una ascensió registrada per l’usuari.
// Guarda la relació amb el cim, la data, les notes, les fotos
// i l’estat de verificació quan l’ascensió s’ha validat des de l’app.
class Ascent {
  const Ascent({
    required this.id,
    required this.userId,
    required this.peakId,
    this.ascentDate,
    this.notes,
    this.isDateLocked = false,
    this.verification,
    this.primaryPhoto,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final int peakId;
  final DateTime? ascentDate;
  final String? notes;
  final bool isDateLocked;
  final AscentVerification? verification;
  final AscentPhoto? primaryPhoto;
  final List<AscentPhoto> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Aquest constructor transforma la resposta del backend en un objecte Ascent.
  // Accepta ascensions manuals i ascensions verificades amb estat de validació.
  factory Ascent.fromJson(Map<String, dynamic> json) {
    return Ascent(
      id: _parseInt(json['id'], 'id'),
      userId: _parseInt(json['user_id'], 'user_id'),
      peakId: _parseInt(json['peak_id'], 'peak_id'),
      ascentDate: _parseOptionalDateOnly(json['ascent_date']),
      notes: _parseNullableString(json['notes']),
      isDateLocked: _parseBool(json['isDateLocked'] ?? json['is_date_locked']),
      verification: _parseOptionalVerification(json['verification']),
      primaryPhoto: _parseOptionalPhoto(json['primaryPhoto']),
      photos: _parsePhotos(json['photos']),
      createdAt: _parseDateTime(json['created_at'], 'created_at'),
      updatedAt: _parseDateTime(json['updated_at'], 'updated_at'),
    );
  }

  // Aquest getter indica si l’ascensió té una data associada.
  // Permet separar els registres cronològics dels registres sense data.
  bool get hasDate => ascentDate != null;

  // Aquest getter indica si l’ascensió té notes útils per mostrar a la interfície.
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  // Aquest getter indica si l’ascensió té alguna imatge associada.
  bool get hasPhotos => photos.isNotEmpty || primaryPhoto != null;

  // Aquest getter indica si l’ascensió té una verificació acceptada.
  // Serveix per mostrar visualment que el registre ha estat validat.
  bool get isVerified => verification?.isVerified ?? false;

  static AscentVerification? _parseOptionalVerification(dynamic value) {
    if (value is Map) {
      return AscentVerification.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    return null;
  }

  static AscentPhoto? _parseOptionalPhoto(dynamic value) {
    if (value is Map) {
      return AscentPhoto.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    return null;
  }

  static List<AscentPhoto> _parsePhotos(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => AscentPhoto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

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

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static DateTime? _parseOptionalDateOnly(dynamic value) {
    if (value == null) {
      return null;
    }

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

    throw const FormatException('La data de l’ascensió no és vàlida');
  }

  static DateTime _parseDateTime(dynamic value, String fieldName) {
    if (value is String) {
      return DateTime.parse(value);
    }

    throw FormatException('El camp "$fieldName" no és vàlid');
  }
}