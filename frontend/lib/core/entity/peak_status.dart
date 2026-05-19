// Aquesta entitat representa l’estat personal que un usuari té sobre un cim.
// Permet saber si el cim està completat, és objectiu, és preferit o té una ascensió verificada.
class PeakStatus {
  const PeakStatus({
    this.id,
    this.userId,
    required this.peakId,
    required this.isCompleted,
    required this.isTarget,
    required this.isFavorite,
    this.hasVerifiedAscent = false,
  });

  final int? id;
  final int? userId;
  final int peakId;
  final bool isCompleted;
  final bool isTarget;
  final bool isFavorite;
  final bool hasVerifiedAscent;

  // Aquest constructor crea un estat buit per a un cim sense registre personal.
  // Permet que la UI treballi amb valors inicials encara que el backend no tingui cap fila.
  factory PeakStatus.emptyForPeak(int peakId) {
    return PeakStatus(
      peakId: peakId,
      isCompleted: false,
      isTarget: false,
      isFavorite: false,
      hasVerifiedAscent: false,
    );
  }

  // Aquest constructor transforma la resposta del backend en un objecte PeakStatus.
  // També interpreta si el cim té alguna ascensió verificada associada.
  factory PeakStatus.fromJson(Map<String, dynamic> json) {
    final parsedPeakId = _parseInt(json['peak_id']);

    if (parsedPeakId == null) {
      throw const FormatException('L\'identificador del cim no és vàlid');
    }

    return PeakStatus(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      peakId: parsedPeakId,
      isCompleted: _parseBool(json['is_completed']),
      isTarget: _parseBool(json['is_target']),
      isFavorite: _parseBool(json['is_favorite']),
      hasVerifiedAscent: _parseBool(
        json['has_verified_ascent'] ?? json['hasVerifiedAscent'],
      ),
    );
  }

  // Aquest getter indica si el cim encara està pendent d’assolir.
  // No és un estat independent, sinó el contrari funcional de completat.
  bool get isPending => !isCompleted;

  // Aquest getter ajuda la interfície a saber si cal mostrar algun indicador visual.
  // Inclou la verificació perquè el catàleg i el mapa puguin destacar aquest estat.
  bool get hasAnyStatus =>
      isCompleted || isTarget || isFavorite || hasVerifiedAscent;

  // Aquest mètode permet crear una còpia de l’estat canviant només els camps necessaris.
  // És útil quan una pantalla actualitza un estat sense perdre la resta d’informació.
  PeakStatus copyWith({
    int? id,
    int? userId,
    int? peakId,
    bool? isCompleted,
    bool? isTarget,
    bool? isFavorite,
    bool? hasVerifiedAscent,
  }) {
    return PeakStatus(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      peakId: peakId ?? this.peakId,
      isCompleted: isCompleted ?? this.isCompleted,
      isTarget: isTarget ?? this.isTarget,
      isFavorite: isFavorite ?? this.isFavorite,
      hasVerifiedAscent: hasVerifiedAscent ?? this.hasVerifiedAscent,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}