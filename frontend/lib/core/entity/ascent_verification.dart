// Aquesta entitat representa l’estat de verificació d’una ascensió.
// Permet saber si una ascensió ha estat validada amb ubicació, si queda pendent
// o si ha estat rebutjada pel backend.
class AscentVerification {
  const AscentVerification({
    required this.id,
    required this.method,
    required this.status,
    this.distanceToPeakMeters,
    this.checkedAt,
    this.reason,
  });

  final int id;
  final String method;
  final String status;
  final double? distanceToPeakMeters;
  final DateTime? checkedAt;
  final String? reason;

  factory AscentVerification.fromJson(Map<String, dynamic> json) {
    return AscentVerification(
      id: _parseInt(json['id'], 'id'),
      method: _parseString(json['method'], 'method'),
      status: _parseString(json['status'], 'status'),
      distanceToPeakMeters: _parseOptionalDouble(
        json['distanceToPeakMeters'] ?? json['distance_to_peak_meters'],
      ),
      checkedAt: _parseOptionalDateTime(
        json['checkedAt'] ?? json['checked_at'],
      ),
      reason: _parseNullableString(json['reason']),
    );
  }

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  static int _parseInt(dynamic value, String fieldName) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('El camp "$fieldName" no és vàlid');
  }

  static String _parseString(dynamic value, String fieldName) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      throw FormatException('El camp "$fieldName" no és vàlid');
    }
    return text;
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
