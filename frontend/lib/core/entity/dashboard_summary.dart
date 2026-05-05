// Aquest model agrupa totes les dades que necessita el dashboard.
// Permet representar tant les estadístiques ja existents com els nous blocs
// pendents del backend sense bloquejar el desenvolupament de la pantalla.
class DashboardSummary {
  const DashboardSummary({
    required this.completedPeaks,
    required this.activeTargets,
    required this.favorites,
    required this.totalAscents,
    required this.uniquePeaksAscended,
    required this.totalAltitudeMeters,
    required this.challengeProgress,
    required this.pendingPeaks,
    required this.favoritePeaks,
    required this.monthlyChallenge,
    required this.recentAscents,
    this.lastAscent,
    this.highestCompletedAltitude,
    this.mostAscendedPeak,
    this.monthlyAscents = const [],
  });

  // Aquest bloc conté els indicadors i llistes que alimenten el dashboard.
  // Permet mostrar el progrés general, els reptes, els cims destacats i l’activitat recent.
  final int completedPeaks;
  final int activeTargets;
  final int favorites;
  final int totalAscents;
  final int uniquePeaksAscended;
  final int totalAltitudeMeters;
  final ChallengeProgress challengeProgress;
  final List<DashboardPeakItem> pendingPeaks;
  final List<DashboardPeakItem> favoritePeaks;
  final MonthlyChallenge monthlyChallenge;
  final List<DashboardRecentAscent> recentAscents;
  final DashboardRecentAscent? lastAscent;
  final DashboardPeakItem? highestCompletedAltitude;
  final DashboardPeakItem? mostAscendedPeak;
  final List<MonthlyAscentsItem> monthlyAscents;

  // Aquest constructor transforma la resposta JSON del backend en un objecte usable pel frontend.
  // Els valors per defecte eviten errors si algun camp encara no està disponible al backend.
  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final completedPeaks = _asInt(json['completedPeaks']);
    final challengeJson = _asMap(json['challengeProgress']);

    return DashboardSummary(
      completedPeaks: completedPeaks,
      activeTargets: _asInt(json['activeTargets']),
      favorites: _asInt(json['favorites']),
      totalAscents: _asInt(json['totalAscents']),
      uniquePeaksAscended: _asInt(json['uniquePeaksAscended']),
      totalAltitudeMeters: _asInt(json['totalAltitudeMeters']),
      challengeProgress: challengeJson.isEmpty
          ? ChallengeProgress.fromCompleted(completedPeaks)
          : ChallengeProgress.fromJson(challengeJson),
      pendingPeaks: _asList(json['pendingPeaks'])
          .map((item) => DashboardPeakItem.fromJson(item))
          .toList(),
      favoritePeaks: _asList(json['favoritePeaks'])
          .map((item) => DashboardPeakItem.fromJson(item))
          .toList(),
      monthlyChallenge: MonthlyChallenge.fromJson(
        _asMap(json['monthlyChallenge']),
      ),
      recentAscents: _asList(json['recentAscents'])
          .map((item) => DashboardRecentAscent.fromJson(item))
          .toList(),
      lastAscent: json['lastAscent'] == null
          ? null
          : DashboardRecentAscent.fromJson(_asMap(json['lastAscent'])),
      highestCompletedAltitude: json['highestCompletedAltitude'] == null
          ? null
          : DashboardPeakItem.fromJson(
              _asMap(json['highestCompletedAltitude'])),
      mostAscendedPeak: json['mostAscendedPeak'] == null
          ? null
          : DashboardPeakItem.fromJson(_asMap(json['mostAscendedPeak'])),
      monthlyAscents: _asList(json['monthlyAscents'])
          .map((item) => MonthlyAscentsItem.fromJson(item))
          .toList(),
    );
  }

  // Aquest mètode crea una nova versió del resum mantenint les dades existents.
  // És útil quan el dashboard i el repte mensual arriben des d'endpoints diferents.
  DashboardSummary copyWith({
    int? completedPeaks,
    int? activeTargets,
    int? favorites,
    int? totalAscents,
    int? uniquePeaksAscended,
    int? totalAltitudeMeters,
    ChallengeProgress? challengeProgress,
    List<DashboardPeakItem>? pendingPeaks,
    List<DashboardPeakItem>? favoritePeaks,
    MonthlyChallenge? monthlyChallenge,
    List<DashboardRecentAscent>? recentAscents,
    DashboardRecentAscent? lastAscent,
    DashboardPeakItem? highestCompletedAltitude,
    DashboardPeakItem? mostAscendedPeak,
    List<MonthlyAscentsItem>? monthlyAscents,
  }) {
    return DashboardSummary(
      completedPeaks: completedPeaks ?? this.completedPeaks,
      activeTargets: activeTargets ?? this.activeTargets,
      favorites: favorites ?? this.favorites,
      totalAscents: totalAscents ?? this.totalAscents,
      uniquePeaksAscended: uniquePeaksAscended ?? this.uniquePeaksAscended,
      totalAltitudeMeters: totalAltitudeMeters ?? this.totalAltitudeMeters,
      challengeProgress: challengeProgress ?? this.challengeProgress,
      pendingPeaks: pendingPeaks ?? this.pendingPeaks,
      favoritePeaks: favoritePeaks ?? this.favoritePeaks,
      monthlyChallenge: monthlyChallenge ?? this.monthlyChallenge,
      recentAscents: recentAscents ?? this.recentAscents,
      lastAscent: lastAscent ?? this.lastAscent,
      highestCompletedAltitude:
          highestCompletedAltitude ?? this.highestCompletedAltitude,
      mostAscendedPeak: mostAscendedPeak ?? this.mostAscendedPeak,
      monthlyAscents: monthlyAscents ?? this.monthlyAscents,
    );
  }
}

// Aquest model representa el progrés del repte principal dels 100 cims.
// El dashboard l’utilitza per mostrar percentatge, completats i objectiu total.
class ChallengeProgress {
  const ChallengeProgress({
    required this.completed,
    required this.target,
    required this.remaining,
    required this.percentage,
  });

  // Aquestes dades descriuen l’estat numèric del repte principal.
  // Permeten calcular i mostrar de manera clara què s’ha completat i què queda pendent.
  final int completed;
  final int target;
  final int remaining;
  final int percentage;

  // Aquest constructor crea el progrés del repte a partir del total de cims completats.
  // S’utilitza com a suport si el backend encara no envia l’objecte challengeProgress.
  factory ChallengeProgress.fromCompleted(int completed) {
    const target = 100;
    final remaining = (target - completed).clamp(0, target).toInt();
    final percentage =
        ((completed / target) * 100).round().clamp(0, 100).toInt();

    return ChallengeProgress(
      completed: completed,
      target: target,
      remaining: remaining,
      percentage: percentage,
    );
  }

  // Aquest constructor crea el progrés del repte a partir del JSON rebut.
  // Si el backend no envia algun valor calculat, el model el genera amb dades bàsiques.
  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    final completed = _asInt(json['completed'] ?? json['current']);
    final target = _asInt(json['target'], defaultValue: 100);
    final remaining = json.containsKey('remaining')
        ? _asInt(json['remaining'])
        : (target - completed).clamp(0, target).toInt();
    final percentage = json.containsKey('percentage')
        ? _asInt(json['percentage'])
        : target == 0
            ? 0
            : ((completed / target) * 100).round().clamp(0, 100).toInt();

    return ChallengeProgress(
      completed: completed,
      target: target,
      remaining: remaining,
      percentage: percentage,
    );
  }
}

// Aquest model representa un cim mostrat dins del dashboard.
// Serveix per als pendents, favorits, cim més alt o cim més repetit.
class DashboardPeakItem {
  const DashboardPeakItem({
    required this.id,
    required this.name,
    this.altitude,
    this.regionName,
    this.imageUrl,
    this.ascentCount,
  });

  // Aquestes dades contenen la informació mínima d’un cim dins del resum.
  // Permeten identificar-lo i mostrar detalls útils sense carregar tota la fitxa completa.
  final int id;
  final String name;
  final int? altitude;
  final String? regionName;
  final String? imageUrl;
  final int? ascentCount;

  // Aquest constructor transforma un cim del JSON en un element visual del dashboard.
  // Accepta camps opcionals i noms alternatius per adaptar-se a la resposta real del backend.
  factory DashboardPeakItem.fromJson(Map<String, dynamic> json) {
    return DashboardPeakItem(
      id: _asInt(json['id'] ?? json['peakId'] ?? json['peak_id']),
      name: _asString(json['name'] ?? json['peakName'] ?? json['peak_name']),
      altitude: json['altitude'] == null &&
              json['peakAltitude'] == null &&
              json['peak_altitude'] == null
          ? null
          : _asInt(
              json['altitude'] ?? json['peakAltitude'] ?? json['peak_altitude'],
            ),
      regionName: _asRegionsText(json['regions']) ??
          _asNullableString(json['regionName'] ?? json['region']),
      imageUrl: _asNullableString(json['imageUrl']),
      ascentCount: json['ascentCount'] == null &&
              json['count'] == null &&
              json['totalAscents'] == null
          ? null
          : _asInt(
              json['ascentCount'] ?? json['count'] ?? json['totalAscents'],
            ),
    );
  }
}

// Aquest model representa el repte mensual del dashboard.
// Permet mostrar un objectiu temporal independent del repte general dels 100 cims.
class MonthlyChallenge {
  const MonthlyChallenge({
    required this.current,
    required this.target,
    required this.percentage,
    required this.unit,
    this.title,
    this.description,
    this.currentLevel = 0,
    this.totalLevels = 0,
    this.isFullyCompleted = false,
  });

  // Aquestes dades defineixen l’estat i la presentació del repte mensual.
  // Permeten mostrar un objectiu proper amb unitat, text descriptiu i percentatge de progrés.
  final int current;
  final int target;
  final int percentage;
  final String unit;
  final String? title;
  final String? description;
  final int currentLevel;
  final int totalLevels;
  final bool isFullyCompleted;

  // Aquest constructor crea el repte mensual a partir de la resposta del backend.
  // Accepta tant el format simple del dashboard com el format complet de /monthly-challenges/current.
  factory MonthlyChallenge.fromJson(Map<String, dynamic> json) {
    final targets = _asIntList(json['targets']);
    final current = _asInt(json['current'] ?? json['currentProgress']);
    final target = json.containsKey('target')
        ? _asInt(json['target'])
        : targets.isEmpty
            ? 0
            : targets.last;
    final percentage = json.containsKey('percentage')
        ? _asInt(json['percentage'])
        : target == 0
            ? 0
            : ((current / target) * 100).round().clamp(0, 100).toInt();
    final type = _asString(json['type']);
    final unit = _monthlyChallengeUnit(type, json['unit']);
    final currentLevel = _asInt(json['currentLevel']);
    final totalLevels = targets.length;

    return MonthlyChallenge(
      current: current,
      target: target,
      percentage: percentage,
      unit: unit,
      title: _asNullableString(json['title']) ?? _monthlyChallengeTitle(type),
      description: _asNullableString(json['description']) ??
          _monthlyChallengeDescription(
            current: current,
            target: target,
            unit: unit,
            currentLevel: currentLevel,
            totalLevels: totalLevels,
          ),
      currentLevel: currentLevel,
      totalLevels: totalLevels,
      isFullyCompleted: _asBool(json['isFullyCompleted']),
    );
  }
}

// Aquest model representa una ascensió recent.
// El dashboard el pot utilitzar per mostrar activitat recent de l’usuari.
class DashboardRecentAscent {
  const DashboardRecentAscent({
    required this.id,
    required this.peakId,
    required this.peakName,
    required this.ascentDate,
    this.altitude,
    this.regionName,
    this.notes,
  });

  // Aquestes dades descriuen una ascensió concreta dins del resum d’activitat.
  // Permeten mostrar quin cim s’ha registrat, quan s’ha fet i informació complementària.
  final int id;
  final int peakId;
  final String peakName;
  final String ascentDate;
  final int? altitude;
  final String? regionName;
  final String? notes;

  // Aquest constructor adapta el JSON d’una ascensió recent al format que espera el frontend.
  // També contempla noms de camp alternatius per mantenir compatibilitat amb el backend.
  factory DashboardRecentAscent.fromJson(Map<String, dynamic> json) {
    return DashboardRecentAscent(
      id: _asInt(json['id']),
      peakId: _asInt(json['peakId'] ?? json['peak_id']),
      peakName:
          _asString(json['peakName'] ?? json['peak_name'] ?? json['name']),
      ascentDate: _asString(json['ascentDate'] ?? json['ascent_date']),
      altitude: json['altitude'] == null &&
              json['peakAltitude'] == null &&
              json['peak_altitude'] == null
          ? null
          : _asInt(
              json['altitude'] ?? json['peakAltitude'] ?? json['peak_altitude'],
            ),
      regionName: _asRegionsText(json['regions']) ??
          _asNullableString(json['regionName'] ?? json['region']),
      notes: _asNullableString(json['notes']),
    );
  }
}

// Aquest model representa el nombre d’ascensions agrupades per mes.
// És útil per a estadístiques i pot alimentar gràfiques futures.
class MonthlyAscentsItem {
  const MonthlyAscentsItem({
    required this.month,
    required this.total,
  });

  // Aquestes dades representen un resum mensual d’activitat.
  // Permeten construir estadístiques temporals sense dependre de cada ascensió individual.
  final String month;
  final int total;

  // Aquest constructor converteix cada registre mensual del JSON en un element d’estadística.
  // Accepta tant total com count per adaptar-se a possibles variants del backend.
  factory MonthlyAscentsItem.fromJson(Map<String, dynamic> json) {
    return MonthlyAscentsItem(
      month: _asString(json['month']),
      total: _asInt(json['total'] ?? json['count']),
    );
  }
}

// Aquestes funcions centralitzen conversions simples del JSON.
// Fan que els models siguin més tolerants mentre el contracte del backend encara evoluciona.

// Aquesta funció transforma valors numèrics o textos en enters.
// Si el valor no és vàlid, retorna un valor per defecte per evitar errors de càrrega.
int _asInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Aquesta funció transforma qualsevol valor simple en text.
// Permet assegurar que els camps obligatoris de tipus String sempre tinguin un valor usable.
String _asString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

// Aquesta funció transforma un valor en text opcional.
// Retorna null quan no hi ha contingut real, evitant mostrar textos buits a la interfície.
String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

// Aquesta funció assegura que un valor rebut sigui un mapa JSON vàlid.
// Facilita crear submodels encara que el backend no enviï l’objecte esperat.
Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

// Aquesta funció assegura que una llista del JSON contingui només mapes compatibles.
// Permet transformar col·leccions de dades sense trencar la pantalla si algun element no és vàlid.
List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

// Aquesta funció converteix la llista de regions del backend en un text llegible.
// Permet mostrar correctament cims que poden pertànyer a més d’una comarca o regió.
String? _asRegionsText(dynamic value) {
  if (value is! List) return null;

  final regions = value
      .map((region) => region.toString().trim())
      .where((region) => region.isNotEmpty)
      .toList();

  if (regions.isEmpty) return null;
  return regions.join(', ');
}

// Aquesta funció transforma una llista de valors numèrics en enters.
// S'utilitza per adaptar els nivells del repte mensual enviats pel backend.
List<int> _asIntList(dynamic value) {
  if (value is! List) return <int>[];

  return value.map(_asInt).where((item) => item > 0).toList();
}

// Aquesta funció transforma valors simples en booleans.
// Permet llegir respostes del backend encara que el valor arribi amb formats diferents.
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

// Aquesta funció adapta el tipus intern del repte mensual a una unitat llegible.
// Manté la targeta independent dels noms tècnics que utilitza el backend.
String _monthlyChallengeUnit(String type, dynamic fallback) {
  final provided = _asNullableString(fallback);
  if (provided != null) return provided;

  switch (type) {
    case 'distinct_regions':
      return 'comarques';
    case 'peaks_completed':
      return 'cims';
    default:
      return 'ascensions';
  }
}

// Aquesta funció genera un títol entenedor quan el backend només envia el tipus del repte.
// Això permet mostrar el repte mensual sense exposar noms interns a l'usuari.
String _monthlyChallengeTitle(String type) {
  switch (type) {
    case 'distinct_regions':
      return 'Repte mensual de comarques';
    case 'peaks_completed':
      return 'Repte mensual de cims';
    default:
      return 'Repte mensual';
  }
}

// Aquesta funció prepara el text resum del repte mensual.
// Inclou el nivell desbloquejat i el progrés total sobre l'objectiu final.
String _monthlyChallengeDescription({
  required int current,
  required int target,
  required String unit,
  required int currentLevel,
  required int totalLevels,
}) {
  final progressText = '$current/$target $unit';

  if (totalLevels == 0) {
    return progressText;
  }

  return 'Nivell $currentLevel/$totalLevels · $progressText';
}
