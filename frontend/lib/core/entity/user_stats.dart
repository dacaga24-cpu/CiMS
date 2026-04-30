// Aquesta entitat agrupa les estadístiques personals de l’usuari.
// La pantalla d’estadístiques la farà servir per mostrar el resum de progrés,
// les últimes ascensions i les mètriques principals de l’activitat registrada.
class UserStats {
  const UserStats({
    required this.completedPeaks,
    required this.activeTargets,
    required this.favorites,
    required this.totalAscents,
    required this.uniquePeaksAscended,
    required this.totalAltitudeMeters,
    required this.monthlyAscents,
    required this.recentAscents,
    this.highestCompletedAltitude,
    this.mostAscendedPeak,
    this.challengeProgress,
  });

  // Aquest bloc recull les mètriques principals que defineixen el progrés de l’usuari.
  // Combina comptadors generals, dades acumulades i resums específics per alimentar la pantalla.
  final int completedPeaks;
  final int activeTargets;
  final int favorites;
  final int totalAscents;
  final int uniquePeaksAscended;
  final int totalAltitudeMeters;
  final List<MonthlyAscentsStats> monthlyAscents;
  final List<RecentAscentStats> recentAscents;
  final int? highestCompletedAltitude;
  final MostAscendedPeakStats? mostAscendedPeak;
  final ChallengeProgressStats? challengeProgress;

  // Aquest constructor transforma la resposta de l’endpoint /api/stats
  // en un objecte preparat per ser utilitzat pel controller i la pantalla.
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      completedPeaks: _parseInt(json['completedPeaks']),
      activeTargets: _parseInt(json['activeTargets']),
      favorites: _parseInt(json['favorites']),
      totalAscents: _parseInt(json['totalAscents'] ?? json['count']),
      uniquePeaksAscended: _parseInt(json['uniquePeaksAscended']),
      totalAltitudeMeters: _parseInt(json['totalAltitudeMeters']),
      highestCompletedAltitude: _parseNullableInt(
        json['highestCompletedAltitude'],
      ),
      mostAscendedPeak: MostAscendedPeakStats.fromNullableJson(
        json['mostAscendedPeak'],
      ),
      challengeProgress: ChallengeProgressStats.fromNullableJson(
        json['challengeProgress'],
      ),
      monthlyAscents: _parseMonthlyAscents(json['monthlyAscents']),
      recentAscents: _parseRecentAscents(
        json['recentAscent'] ?? json['recentAscents'],
      ),
    );
  }

  // Aquest getter indica si l’usuari encara no té activitat registrada.
  // Serà útil per mostrar un estat buit més clar a la pantalla.
  bool get hasNoActivity => totalAscents == 0 && completedPeaks == 0;

  // Aquest mètode transforma la llista mensual rebuda del backend en objectes del domini.
  // Si la resposta no té el format esperat, retorna una llista buida per evitar errors a la UI.
  static List<MonthlyAscentsStats> _parseMonthlyAscents(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(MonthlyAscentsStats.fromJson)
        .toList();
  }

  // Aquest mètode transforma les ascensions recents rebudes del backend en objectes preparats.
  // Permet que la pantalla treballi sempre amb una llista segura i tipada.
  static List<RecentAscentStats> _parseRecentAscents(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(RecentAscentStats.fromJson)
        .toList();
  }

  // Aquest mètode converteix diferents formats numèrics en enters.
  // Dona robustesa davant possibles variacions en la resposta del backend.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Aquest mètode converteix valors opcionals en enters quan existeixen.
  // Manté el valor nul quan la dada no arriba informada pel backend.
  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// Aquesta entitat representa les ascensions agrupades per mes.
// Servirà per alimentar el gràfic visual de progrés de la pantalla.
class MonthlyAscentsStats {
  const MonthlyAscentsStats({
    required this.month,
    required this.total,
  });

  // El backend envia any i mes per separat com a enters; aquí es combinen en
  // una cadena "YYYY-MM" perquè la UI pugui ordenar i etiquetar el gràfic
  // sense haver de manipular dos camps independents. El nombre d'ascensions
  // arriba al backend com a "count" i es manté com a "total" al frontend per
  // no propagar canvis a tots els consumidors del widget.
  final String month;
  final int total;

  // Aquest constructor transforma cada resum mensual del backend en una entitat tipada.
  // Si el backend canviés en el futur i tornés a enviar el camp "month" com a
  // cadena, el fallback continua funcionant gràcies al doble accés.
  factory MonthlyAscentsStats.fromJson(Map<String, dynamic> json) {
    return MonthlyAscentsStats(
      month: _composeMonthLabel(
        json['year'],
        json['month'],
      ),
      total: _parseInt(json['count'] ?? json['total']),
    );
  }

  // Aquest mètode combina any i mes en l'etiqueta "YYYY-MM" amb dos dígits
  // per al mes. Si el primer paràmetre ja és una cadena (perquè el backend
  // hagués canviat el contracte), es retorna tal qual. Si no es pot
  // interpretar res, retorna cadena buida perquè la UI la pugui filtrar.
  static String _composeMonthLabel(dynamic year, dynamic month) {
    if (year == null && month is String) {
      return month;
    }
    final parsedYear = _parseInt(year);
    final parsedMonth = _parseInt(month);
    if (parsedYear == 0 || parsedMonth == 0) {
      return '';
    }
    final monthLabel = parsedMonth.toString().padLeft(2, '0');
    return '$parsedYear-$monthLabel';
  }

  // Aquest mètode assegura que el total mensual sempre sigui un enter vàlid.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

// Aquesta entitat representa el cim que l’usuari ha coronat més vegades.
// S’utilitzarà per mostrar la targeta de “més cops coronat”.
class MostAscendedPeakStats {
  const MostAscendedPeakStats({
    required this.peakId,
    required this.peakName,
    required this.totalAscents,
    this.peakAltitude,
    this.regions = const [],
    this.imageUrl,
  });

  // Aquest bloc conté la informació necessària per destacar el cim més repetit.
  // peakAltitude i regions vénen del backend (CIMS-181) i estan disponibles
  // per a futures iteracions de la UI. La imatge és opcional perquè el
  // backend actual no l'envia.
  final int peakId;
  final String peakName;
  final int totalAscents;
  final int? peakAltitude;
  final List<String> regions;
  final String? imageUrl;

  // Aquest constructor transforma la dada del cim més repetit en un objecte preparat per la UI.
  factory MostAscendedPeakStats.fromJson(Map<String, dynamic> json) {
    return MostAscendedPeakStats(
      peakId: _parseInt(json['peakId'] ?? json['peak_id']),
      peakName: (json['peakName'] ?? json['peak_name'])?.toString() ?? '',
      totalAscents: _parseInt(json['totalAscents'] ?? json['count']),
      peakAltitude: _parseNullableInt(
        json['peakAltitude'] ?? json['peak_altitude'],
      ),
      regions: _parseRegions(json['regions']),
      imageUrl: _parseNullableString(json['imageUrl']),
    );
  }

  // Aquest mètode evita crear la targeta de cim repetit quan el backend no envia informació.
  static MostAscendedPeakStats? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MostAscendedPeakStats.fromJson(value);
    }
    return null;
  }

  // Aquest mètode converteix els valors numèrics del cim més repetit a enters segurs.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Aquest mètode interpreta valors numèrics opcionals com l'altitud del cim
  // i manté null quan el backend no els envia.
  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Aquest mètode normalitza la llista de comarques retornada pel backend.
  // Filtra cadenes buides perquè la UI no hagi de tractar valors espuris.
  static List<String> _parseRegions(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((region) => region.toString().trim())
        .where((region) => region.isNotEmpty)
        .toList();
  }

  // Aquest mètode valida textos opcionals com la URL de la imatge.
  // Retorna null quan el backend envia un valor buit o inexistent.
  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

// Aquesta entitat representa el progrés d'un repte concret.
// En el disseny actual encaixa amb el repte rolling dels 100 cims, amb una
// finestra d'un any que acaba en l'última ascensió de l'usuari.
class ChallengeProgressStats {
  const ChallengeProgressStats({
    required this.current,
    required this.target,
    this.percentage,
    this.windowStart,
    this.windowEnd,
  });

  // current és el nombre de cims únics dins la finestra rolling.
  // El backend envia aquest valor com a "completed"; aquí es manté el nom
  // "current" perquè el controller i el widget el consumeixen amb aquest nom.
  // percentage queda nullable perquè el backend NO l'envia: el controller el
  // calcula com a fallback. Si en el futur el backend l'afegís, aquest model
  // ja el sap llegir.
  // windowStart i windowEnd són les dates que delimiten la finestra rolling.
  final int current;
  final int target;
  final int? percentage;
  final String? windowStart;
  final String? windowEnd;

  // Aquest constructor transforma la informació del repte rebuda del backend.
  // Accepta tant "completed" (nom actual al backend) com "current" (alias
  // intern) per ser tolerant a un futur canvi de contracte.
  factory ChallengeProgressStats.fromJson(Map<String, dynamic> json) {
    return ChallengeProgressStats(
      current: _parseInt(json['completed'] ?? json['current']),
      target: _parseInt(json['target']),
      percentage: _parseNullableInt(json['percentage']),
      windowStart: _parseNullableString(json['windowStart']),
      windowEnd: _parseNullableString(json['windowEnd']),
    );
  }

  // Aquest mètode permet que el progrés del repte sigui opcional.
  // Si el backend no l’envia, la pantalla pot calcular o mostrar un valor per defecte.
  static ChallengeProgressStats? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ChallengeProgressStats.fromJson(value);
    }
    return null;
  }

  // Aquest mètode assegura que els valors del repte sempre siguin enters.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Aquest mètode interpreta valors numèrics opcionals (com el percentatge
  // que el backend pot afegir en el futur) sense perdre la distinció entre
  // "no enviat" i "zero explícit".
  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Aquest mètode normalitza les dates ISO de la finestra del repte.
  // Manté null si el backend no envia la dada.
  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

// Aquesta entitat representa una ascensió recent amb la informació necessària
// per mostrar-la en el llistat inferior de la pantalla d’estadístiques.
class RecentAscentStats {
  const RecentAscentStats({
    required this.id,
    required this.peakId,
    required this.peakName,
    required this.altitude,
    required this.ascentDate,
    required this.regions,
  });

  // Aquest bloc conté les dades que es mostren a cada element del llistat recent.
  // Inclou identificadors, informació del cim, data i classificació territorial.
  final int id;
  final int peakId;
  final String peakName;
  final int altitude;
  final DateTime ascentDate;
  final List<String> regions;

  // Aquest constructor transforma una ascensió recent del backend en una entitat de pantalla.
  factory RecentAscentStats.fromJson(Map<String, dynamic> json) {
    return RecentAscentStats(
      id: _parseInt(json['id']),
      peakId: _parseInt(json['peakId'] ?? json['peak_id']),
      peakName: (json['peakName'] ?? json['peak_name'])?.toString() ?? '',
      altitude: _parseInt(
        json['altitude'] ?? json['peakAltitude'] ?? json['peak_altitude'],
      ),
      ascentDate: _parseDateOnly(json['ascentDate'] ?? json['ascent_date']),
      regions: _parseRegions(json['regions']),
    );
  }

  // Aquest getter prepara les comarques en un format senzill per a la UI.
  String get formattedRegions => regions.join(', ');

  // Aquest mètode transforma la llista de regions del backend en textos nets.
  // Elimina valors buits per evitar mostrar separadors o informació sense contingut.
  static List<String> _parseRegions(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((region) => region.toString().trim())
        .where((region) => region.isNotEmpty)
        .toList();
  }

  // Aquest mètode converteix identificadors i altituds a enters segurs.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Aquest mètode transforma la data de l’ascensió en una data simple sense hora.
  // Això encaixa amb el funcionament del registre d’ascensions, que es mostra per dia.
  static DateTime _parseDateOnly(dynamic value) {
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

    return DateTime.now();
  }
}