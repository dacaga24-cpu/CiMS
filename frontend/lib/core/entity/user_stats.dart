// Aquesta entitat agrupa les estadístiques personals de l’usuari.
// Permet mostrar progrés, rànquings, historial mensual, metres acumulats i ratxes.
class UserStats {
  const UserStats({
    required this.completedPeaks,
    required this.activeTargets,
    required this.favorites,
    required this.totalAscents,
    required this.uniquePeaksAscended,
    required this.totalAltitudeMeters,
    required this.totalAltitudeMetersAllTime,
    required this.selectedRange,
    required this.monthlyAscents,
    required this.topAscendedPeaks,
    required this.monthlyStreak,
    required this.recentAscents,
    this.highestCompletedAltitude,
    this.mostAscendedPeak,
    this.challengeProgress,
  });

  // Aquestes dades defineixen el resum principal del progrés de l’usuari.
  // Combinen comptadors generals, activitat recent, rànquings i dades temporals.
  final int completedPeaks;
  final int activeTargets;
  final int favorites;
  final int totalAscents;
  final int uniquePeaksAscended;
  final int totalAltitudeMeters;
  final int totalAltitudeMetersAllTime;
  final String selectedRange;
  final List<MonthlyAscentsStats> monthlyAscents;
  final List<MostAscendedPeakStats> topAscendedPeaks;
  final MonthlyStreakStats monthlyStreak;
  final List<RecentAscentStats> recentAscents;
  final int? highestCompletedAltitude;
  final MostAscendedPeakStats? mostAscendedPeak;
  final ChallengeProgressStats? challengeProgress;

  // Aquest constructor transforma la resposta del backend en estadístiques d’usuari.
  // Aplica valors segurs perquè la pantalla pugui carregar encara que falti algun camp.
  factory UserStats.fromJson(Map<String, dynamic> json) {
    final totalAltitudeMeters = _parseInt(json['totalAltitudeMeters']);
    final topAscendedPeaks = _parseTopAscendedPeaks(json['topAscendedPeaks']);

    return UserStats(
      completedPeaks: _parseInt(json['completedPeaks']),
      activeTargets: _parseInt(json['activeTargets']),
      favorites: _parseInt(json['favorites']),
      totalAscents: _parseInt(json['totalAscents'] ?? json['count']),
      uniquePeaksAscended: _parseInt(json['uniquePeaksAscended']),
      totalAltitudeMeters: totalAltitudeMeters,
      totalAltitudeMetersAllTime: _parseInt(
        json['totalAltitudeMetersAllTime'],
        defaultValue: totalAltitudeMeters,
      ),
      selectedRange: _parseString(json['selectedRange'], defaultValue: 'year'),
      highestCompletedAltitude: _parseNullableInt(
        json['highestCompletedAltitude'],
      ),
      topAscendedPeaks: topAscendedPeaks,
      mostAscendedPeak: MostAscendedPeakStats.fromNullableJson(
            json['mostAscendedPeak'],
          ) ??
          (topAscendedPeaks.isEmpty ? null : topAscendedPeaks.first),
      challengeProgress: ChallengeProgressStats.fromNullableJson(
        json['challengeProgress'],
      ),
      monthlyAscents: _parseMonthlyAscents(json['monthlyAscents']),
      monthlyStreak: MonthlyStreakStats.fromJson(
        _parseMap(json['monthlyStreak']),
      ),
      recentAscents: _parseRecentAscents(
        json['recentAscent'] ?? json['recentAscents'],
      ),
    );
  }

  // Aquest getter indica si l’usuari encara no té activitat registrada.
  // Permet mostrar un estat buit més clar a la pantalla.
  bool get hasNoActivity => totalAscents == 0 && completedPeaks == 0;

  // Aquest mètode transforma la llista mensual rebuda del backend.
  // Si la resposta no té el format esperat, retorna una llista buida.
  static List<MonthlyAscentsStats> _parseMonthlyAscents(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => MonthlyAscentsStats.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  // Aquest mètode transforma el rànquing de cims més repetits.
  // Permet mostrar el top de cims sense dependre directament del JSON.
  static List<MostAscendedPeakStats> _parseTopAscendedPeaks(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => MostAscendedPeakStats.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  // Aquest mètode transforma les ascensions recents rebudes del backend.
  // Es manté per alimentar fluxos que encara mostren activitat recent.
  static List<RecentAscentStats> _parseRecentAscents(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => RecentAscentStats.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  // Aquest mètode assegura que un valor rebut sigui un mapa JSON vàlid.
  // Facilita crear submodels encara que el backend no enviï l’objecte esperat.
  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  // Aquestes funcions converteixen valors simples del JSON a tipus segurs.
  // Permeten aplicar valors per defecte quan algun camp no arriba informat.
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    final text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }
}

// Aquesta entitat representa les ascensions agrupades per mes.
// Serveix per alimentar el gràfic d’evolució de la pantalla d’estadístiques.
class MonthlyAscentsStats {
  const MonthlyAscentsStats({
    required this.month,
    required this.total,
  });

  // Aquestes dades representen un resum mensual d’activitat.
  // El model normalitza el mes perquè la UI treballi sempre amb el mateix format.
  final String month;
  final int total;

  // Aquest constructor transforma cada resum mensual en una entitat tipada.
  // Accepta variants de nom com total o count segons la resposta del backend.
  factory MonthlyAscentsStats.fromJson(Map<String, dynamic> json) {
    return MonthlyAscentsStats(
      month: _composeMonthLabel(
        json['year'],
        json['month'],
      ),
      total: _parseInt(json['count'] ?? json['total']),
    );
  }

  // Aquest getter retorna l’abreviatura del mes en català.
  // Permet mostrar una etiqueta curta sota cada barra del gràfic.
  String get shortMonthLabel {
    final monthNumber = _monthNumberFromLabel(month);

    const labels = [
      'GEN',
      'FEB',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OCT',
      'NOV',
      'DES',
    ];

    if (monthNumber < 1 || monthNumber > 12) {
      return '';
    }

    return labels[monthNumber - 1];
  }

  // Aquest mètode combina any i mes en l’etiqueta YYYY-MM.
  // Si ja arriba una cadena mensual, es conserva el valor rebut.
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

  // Aquest mètode extreu el número de mes d’una etiqueta YYYY-MM.
  // Si el format no és vàlid, retorna zero perquè la UI pugui mostrar un buit.
  static int _monthNumberFromLabel(String value) {
    if (value.length < 7) return 0;
    return int.tryParse(value.substring(5, 7)) ?? 0;
  }

  // Aquest mètode assegura que el total mensual sigui un enter vàlid.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

// Aquesta entitat representa un cim que l’usuari ha coronat diverses vegades.
// També s’utilitza per construir el rànquing de cims més repetits.
class MostAscendedPeakStats {
  const MostAscendedPeakStats({
    required this.peakId,
    required this.peakName,
    required this.totalAscents,
    this.peakAltitude,
    this.regions = const [],
    this.imageUrl,
  });

  // Aquestes dades permeten destacar cims repetits dins de les estadístiques.
  // Inclouen identificació, nombre d’ascensions, altitud, regions i imatge opcional.
  final int peakId;
  final String peakName;
  final int totalAscents;
  final int? peakAltitude;
  final List<String> regions;
  final String? imageUrl;

  // Aquest constructor transforma la dada del cim repetit en un objecte preparat per la UI.
  factory MostAscendedPeakStats.fromJson(Map<String, dynamic> json) {
    return MostAscendedPeakStats(
      peakId: _parseInt(json['peakId'] ?? json['peak_id']),
      peakName: (json['peakName'] ?? json['peak_name'])?.toString() ?? '',
      totalAscents: _parseInt(json['totalAscents'] ?? json['count']),
      peakAltitude: _parseNullableInt(
        json['peakAltitude'] ?? json['peak_altitude'],
      ),
      regions: _parseRegions(json['regions']),
      imageUrl: _parseNullableString(json['imageUrl'] ?? json['image_url']),
    );
  }

  // Aquest mètode evita crear el model quan el backend no envia informació.
  static MostAscendedPeakStats? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MostAscendedPeakStats.fromJson(value);
    }

    if (value is Map) {
      return MostAscendedPeakStats.fromJson(
        Map<String, dynamic>.from(value),
      );
    }

    return null;
  }

  // Aquest getter prepara les comarques en un format llegible per a la UI.
  String get formattedRegions => regions.join(', ');

  // Aquestes funcions adapten valors del JSON a tipus segurs.
  // Permeten llegir identificadors, altituds, regions i textos opcionals.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _parseRegions(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((region) => region.toString().trim())
        .where((region) => region.isNotEmpty)
        .toList();
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

// Aquesta entitat representa la ratxa mensual d’ascensions.
// Comptabilitza mesos consecutius amb almenys una ascensió datada.
class MonthlyStreakStats {
  const MonthlyStreakStats({
    required this.current,
    required this.best,
  });

  // Aquestes dades indiquen la ratxa actual i la millor ratxa registrada.
  final int current;
  final int best;

  // Aquest constructor transforma la resposta del backend en una ratxa usable.
  // Si no arriba cap dada, retorna zeros per mantenir la pantalla estable.
  factory MonthlyStreakStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStreakStats(
      current: _parseInt(json['current']),
      best: _parseInt(json['best']),
    );
  }

  // Aquest mètode assegura que els valors de ratxa siguin enters vàlids.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

// Aquesta entitat representa el progrés d’un repte concret.
// En el disseny actual encaixa amb el repte dels 100 cims.
class ChallengeProgressStats {
  const ChallengeProgressStats({
    required this.current,
    required this.target,
    this.percentage,
    this.windowStart,
    this.windowEnd,
  });

  // Aquestes dades indiquen el progrés del repte i la seva finestra temporal.
  final int current;
  final int target;
  final int? percentage;
  final String? windowStart;
  final String? windowEnd;

  // Aquest constructor transforma la informació del repte rebuda del backend.
  // Accepta current o completed per tolerar variants del contracte.
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
  static ChallengeProgressStats? fromNullableJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ChallengeProgressStats.fromJson(value);
    }

    if (value is Map) {
      return ChallengeProgressStats.fromJson(
        Map<String, dynamic>.from(value),
      );
    }

    return null;
  }

  // Aquestes funcions adapten valors del JSON a tipus segurs.
  // Permeten llegir el progrés i les dates opcionals de la finestra del repte.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

// Aquesta entitat representa una ascensió recent amb informació resumida.
// Es manté per mostrar activitat recent en estadístiques o altres pantalles.
class RecentAscentStats {
  const RecentAscentStats({
    required this.id,
    required this.peakId,
    required this.peakName,
    required this.altitude,
    required this.ascentDate,
    required this.regions,
    this.imageUrl,
  });

  // Aquestes dades descriuen una ascensió recent i el cim associat.
  // La imatge és opcional i es mostra només quan el backend retorna una URL pública.
  final int id;
  final int peakId;
  final String peakName;
  final int altitude;
  final DateTime ascentDate;
  final List<String> regions;
  final String? imageUrl;

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
      imageUrl: _parseNullableString(json['imageUrl'] ?? json['image_url']),
    );
  }

  // Aquest getter prepara les comarques en un format llegible per a la UI.
  String get formattedRegions => regions.join(', ');

  // Aquestes funcions adapten valors del JSON a tipus segurs.
  // Permeten llegir regions, identificadors, altituds, dates i textos opcionals.
  static List<String> _parseRegions(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((region) => region.toString().trim())
        .where((region) => region.isNotEmpty)
        .toList();
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

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

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}