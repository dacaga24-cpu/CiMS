// Aquesta entitat representa l’estat de verificació d’una ascensió.
// Permet saber si una ascensió ha estat validada, queda pendent o ha estat rebutjada.
class AscentVerification {
  const AscentVerification({
    required this.id,
    required this.method,
    required this.status,
    this.distanceToPeakMeters,
    this.checkedAt,
    this.reason,
  });

  // Aquestes dades descriuen el resultat de la verificació.
  // Inclouen el mètode utilitzat, l’estat final i informació útil per mostrar el motiu.
  final int id;
  final String method;
  final String status;
  final double? distanceToPeakMeters;
  final DateTime? checkedAt;
  final String? reason;

  // Aquest constructor transforma la resposta del backend en una verificació d’ascensió.
  // Accepta diferents noms de camp per mantenir compatibilitat amb el format rebut.
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

  // Aquests accessors faciliten consultar l’estat de la verificació des de la interfície.
  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  // Aquestes funcions adapten valors del JSON a tipus segurs.
  // Permeten validar camps obligatoris i tolerar valors opcionals absents.
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