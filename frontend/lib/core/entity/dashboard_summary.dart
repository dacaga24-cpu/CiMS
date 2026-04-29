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
    return DashboardSummary(
      completedPeaks: _asInt(json['completedPeaks']),
      activeTargets: _asInt(json['activeTargets']),
      favorites: _asInt(json['favorites']),
      totalAscents: _asInt(json['totalAscents']),
      uniquePeaksAscended: _asInt(json['uniquePeaksAscended']),
      totalAltitudeMeters: _asInt(json['totalAltitudeMeters']),
      challengeProgress: ChallengeProgress.fromJson(
        _asMap(json['challengeProgress']),
      ),
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
          : DashboardPeakItem.fromJson(_asMap(json['highestCompletedAltitude'])),
      mostAscendedPeak: json['mostAscendedPeak'] == null
          ? null
          : DashboardPeakItem.fromJson(_asMap(json['mostAscendedPeak'])),
      monthlyAscents: _asList(json['monthlyAscents'])
          .map((item) => MonthlyAscentsItem.fromJson(item))
          .toList(),
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

  // Aquest constructor crea el progrés del repte a partir del JSON rebut.
  // Si el backend no envia algun valor calculat, el model el genera amb dades bàsiques.
  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    final completed = _asInt(json['completed']);
    final target = _asInt(json['target'], defaultValue: 100);
    final remaining = json.containsKey('remaining')
        ? _asInt(json['remaining'])
        : (target - completed).clamp(0, target);
    final percentage = json.containsKey('percentage')
        ? _asInt(json['percentage'])
        : target == 0
            ? 0
            : ((completed / target) * 100).round().clamp(0, 100);

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
  // Accepta camps opcionals perquè cada secció pot necessitar només una part de la informació.
  factory DashboardPeakItem.fromJson(Map<String, dynamic> json) {
    return DashboardPeakItem(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      altitude: json['altitude'] == null ? null : _asInt(json['altitude']),
      regionName: _asNullableString(json['regionName'] ?? json['region']),
      imageUrl: _asNullableString(json['imageUrl']),
      ascentCount: json['ascentCount'] == null ? null : _asInt(json['ascentCount']),
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
  });

  // Aquestes dades defineixen l’estat i la presentació del repte mensual.
  // Permeten mostrar un objectiu proper amb unitat, text descriptiu i percentatge de progrés.
  final int current;
  final int target;
  final int percentage;
  final String unit;
  final String? title;
  final String? description;

  // Aquest constructor crea el repte mensual a partir de la resposta del backend.
  // Si el percentatge no arriba calculat, es genera a partir del valor actual i l’objectiu.
  factory MonthlyChallenge.fromJson(Map<String, dynamic> json) {
    final current = _asInt(json['current']);
    final target = _asInt(json['target']);
    final percentage = json.containsKey('percentage')
        ? _asInt(json['percentage'])
        : target == 0
            ? 0
            : ((current / target) * 100).round().clamp(0, 100);

    return MonthlyChallenge(
      current: current,
      target: target,
      percentage: percentage,
      unit: _asString(json['unit'], defaultValue: 'ascents'),
      title: _asNullableString(json['title']),
      description: _asNullableString(json['description']),
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
      peakName: _asString(json['peakName'] ?? json['peak_name'] ?? json['name']),
      ascentDate: _asString(json['ascentDate'] ?? json['ascent_date']),
      altitude: json['altitude'] == null ? null : _asInt(json['altitude']),
      regionName: _asNullableString(json['regionName'] ?? json['region']),
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