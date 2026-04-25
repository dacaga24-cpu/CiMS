// Aquesta entitat representa l’estat personal que un usuari té sobre un cim.
// Permet saber si el cim està completat, marcat com a objectiu o com a preferit.
// L’estat pendent no es desa com a camp propi, sinó que es calcula a partir de si
// el cim encara no està completat.
class PeakStatus {
  const PeakStatus({
    this.id,
    this.userId,
    required this.peakId,
    required this.isCompleted,
    required this.isTarget,
    required this.isFavorite,
  });

  final int? id;
  final int? userId;
  final int peakId;
  final bool isCompleted;
  final bool isTarget;
  final bool isFavorite;

  // Aquest constructor crea un estat buit per a un cim que encara no té cap registre
  // personal associat al backend. És útil per mostrar el detall del cim sense error
  // encara que l’usuari no l’hagi marcat mai.
  factory PeakStatus.emptyForPeak(int peakId) {
    return PeakStatus(
      peakId: peakId,
      isCompleted: false,
      isTarget: false,
      isFavorite: false,
    );
  }

  // Aquest constructor transforma la resposta del backend en un objecte PeakStatus.
  // Accepta els noms de camps que retorna la base de dades i també possibles variants
  // en camelCase per mantenir l’entitat flexible davant petits canvis de format.
  factory PeakStatus.fromJson(Map<String, dynamic> json) {
    final parsedPeakId = _parseInt(json['peak_id'] ?? json['peakId']);

    if (parsedPeakId == null) {
      throw const FormatException('L\'identificador del cim no és vàlid');
    }

    return PeakStatus(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id'] ?? json['userId']),
      peakId: parsedPeakId,
      isCompleted: _parseBool(json['is_completed'] ?? json['isCompleted']),
      isTarget: _parseBool(json['is_target'] ?? json['isTarget']),
      isFavorite: _parseBool(json['is_favorite'] ?? json['isFavorite']),
    );
  }

  // Aquest getter indica si el cim encara està pendent d’assolir.
  // No és un estat independent, sinó el contrari funcional de completat.
  bool get isPending => !isCompleted;

  // Aquest getter ajuda la interfície a saber si cal mostrar algun indicador visual
  // dins del catàleg o altres pantalles.
  bool get hasAnyStatus => isCompleted || isTarget || isFavorite;

  // Aquest mètode permet crear una còpia de l’estat canviant només els camps necessaris.
  // Serà útil quan els botons del detall activin o desactivin un estat concret.
  PeakStatus copyWith({
    int? id,
    int? userId,
    int? peakId,
    bool? isCompleted,
    bool? isTarget,
    bool? isFavorite,
  }) {
    return PeakStatus(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      peakId: peakId ?? this.peakId,
      isCompleted: isCompleted ?? this.isCompleted,
      isTarget: isTarget ?? this.isTarget,
      isFavorite: isFavorite ?? this.isFavorite,
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