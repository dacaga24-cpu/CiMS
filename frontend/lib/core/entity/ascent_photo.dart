// Aquesta entitat representa una foto associada a una ascensió.
// Pot ser una imatge de record, una foto principal o una evidència
// utilitzada per validar una ascensió verificada.
class AscentPhoto {
  const AscentPhoto({
    required this.id,
    this.ascentId,
    required this.storagePath,
    required this.isPrimary,
    this.isVerificationEvidence = false,
    this.downloadUrl,
    this.createdAt,
  });

  final int id;
  final int? ascentId;
  final String storagePath;
  final bool isPrimary;
  final bool isVerificationEvidence;
  final String? downloadUrl;
  final DateTime? createdAt;

  factory AscentPhoto.fromJson(Map<String, dynamic> json) {
    return AscentPhoto(
      id: _parseInt(json['id'], 'id'),
      ascentId: _parseOptionalInt(json['ascentId'] ?? json['ascent_id']),
      storagePath: _parseString(
        json['storagePath'] ?? json['storage_path'],
        'storagePath',
      ),
      isPrimary: _parseBool(json['isPrimary'] ?? json['is_primary']),
      isVerificationEvidence: _parseBool(
        json['isVerificationEvidence'] ?? json['is_verification_evidence'],
      ),
      downloadUrl: _parseNullableString(
        json['downloadUrl'] ?? json['download_url'],
      ),
      createdAt: _parseOptionalDateTime(json['createdAt'] ?? json['created_at']),
    );
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

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _parseString(dynamic value, String fieldName) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      throw FormatException('El camp "$fieldName" no és vàlid');
    }
    return text;
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

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}