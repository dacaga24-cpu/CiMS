import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/foundation.dart';

// Aquest model concentra els filtres compartits entre el catàleg i el mapa.
// Existeix una única instància (PeaksFilterState.shared) perquè quan l'usuari
// aplica un filtre des d'una pantalla, l'altra el reflecteixi automàticament
// en lloc de mantenir estats independents que es desincronitzen al canviar
// de pestanya.
//
// Estén ChangeNotifier per poder avisar als controllers que es subscriguin
// quan l'estat dels filtres canvi i així recarregar els cims sense que la UI
// hagi de coordinar manualment les dues pantalles.
class PeaksFilterState extends ChangeNotifier {
  // Aquest constructor privat impedeix crear instàncies addicionals.
  // L'única manera d'accedir al filtre és via PeaksFilterState.shared, cosa
  // que garanteix que tot el frontend treballi amb el mateix estat.
  PeaksFilterState._();

  // Instància compartida que viu tot el cicle de vida de l'aplicació.
  // El controller del catàleg i el del mapa s'hi subscriuen al constructor i
  // es desconnecten al dispose perquè no quedin listeners actius.
  static final PeaksFilterState shared = PeaksFilterState._();

  // Aquest bloc guarda els filtres que l’usuari pot aplicar sobre els cims.
  // Es manté en un model separat perquè diferents pantalles puguin reutilitzar el mateix estat.
  int? selectedRegionId;
  int? minAltitude;
  int? maxAltitude;
  PeakStatusFilter selectedStatusFilter = PeakStatusFilter.none;

  // El filtre per clima consta de dues parts: la data ISO (YYYY-MM-DD) i
  // el conjunt de condicions normalitzades. Es modelen separadament
  // perquè la UI pugui mantenir l'estat parcial mentre l'usuari està
  // configurant el panell; només es considera "actiu" quan totes dues
  // parts estan informades, perquè enviar només una al backend no té
  // sentit (faria 400).
  String? weatherDate;
  Set<WeatherConditionType> weatherConditions = <WeatherConditionType>{};

  // Indica si el filtre meteorològic té tots dos camps informats i, per
  // tant, està llest per enviar-se al backend. La UI l'utilitza per
  // decidir si afegir-lo al resum de filtres actius i si pintar el chip
  // del bottom-sheet com a "seleccionat".
  bool get hasActiveWeatherFilter =>
      weatherDate != null &&
      weatherDate!.isNotEmpty &&
      weatherConditions.isNotEmpty;

  // Indica si hi ha algun filtre aplicat.
  // La UI ho utilitza per mostrar o ocultar el resum de filtres.
  bool get hasActiveFilters =>
      selectedRegionId != null ||
      minAltitude != null ||
      maxAltitude != null ||
      selectedStatusFilter != PeakStatusFilter.none ||
      hasActiveWeatherFilter;

  // Aplica els filtres escollits des del panell visual.
  // Només notifica si algun valor ha canviat respecte a l'estat anterior, per
  // evitar disparar recàrregues redundants quan l'usuari obre el panell i
  // tanca sense modificar res. Aquesta defensa és especialment rellevant
  // perquè dos controllers (catàleg i mapa) escolten la mateixa instància:
  // sense aquesta comparació, "Aplica" sense canvis dispararia dos GETs.
  void apply({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    PeakStatusFilter statusFilter = PeakStatusFilter.none,
    String? weatherDate,
    Set<WeatherConditionType>? weatherConditions,
  }) {
    final normalizedConditions = weatherConditions == null
        ? <WeatherConditionType>{}
        : Set<WeatherConditionType>.from(weatherConditions);

    final changed = selectedRegionId != regionId ||
        this.minAltitude != minAltitude ||
        this.maxAltitude != maxAltitude ||
        selectedStatusFilter != statusFilter ||
        this.weatherDate != weatherDate ||
        !_setEquals(this.weatherConditions, normalizedConditions);

    selectedRegionId = regionId;
    this.minAltitude = minAltitude;
    this.maxAltitude = maxAltitude;
    selectedStatusFilter = statusFilter;
    this.weatherDate = weatherDate;
    this.weatherConditions = normalizedConditions;

    if (changed) {
      notifyListeners();
    }
  }

  // Aquest mètode compara dos conjunts ignorant l'ordre, que és el que
  // necessitem per als filtres meteorològics: l'usuari pot triar les
  // mateixes condicions en ordres diferents i no s'ha de considerar un
  // canvi real.
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  // Reinicia tots els filtres i deixa la cerca sense restriccions addicionals.
  // També notifica els listeners. Si ja estaven tots a zero, evita la
  // notificació innecessària per no disparar recàrregues redundants.
  void clear() {
    final wasActive = hasActiveFilters;
    selectedRegionId = null;
    minAltitude = null;
    maxAltitude = null;
    selectedStatusFilter = PeakStatusFilter.none;
    weatherDate = null;
    weatherConditions = <WeatherConditionType>{};
    if (wasActive) {
      notifyListeners();
    }
  }

  // Aquest mètode neteja només el filtre meteorològic, conservant la
  // resta de filtres (comarca, altitud, estat). Es fa servir des del
  // snackbar que apareix quan el proveïdor meteorològic no està
  // disponible: l'acció "Treure filtre" permet a l'usuari recuperar el
  // catàleg sense haver d'obrir el panell de filtres ni perdre la
  // configuració de la resta de criteris.
  void clearWeatherFilter() {
    final wasActive = weatherDate != null || weatherConditions.isNotEmpty;
    if (!wasActive) {
      return;
    }
    weatherDate = null;
    weatherConditions = <WeatherConditionType>{};
    notifyListeners();
  }

  // Retorna el nom de la regió seleccionada a partir del seu identificador.
  // Això permet mostrar un resum entenedor sense duplicar cerques als controllers.
  String? selectedRegionName(List<Region> availableRegions) {
    final regionId = selectedRegionId;

    if (regionId == null) {
      return null;
    }

    for (final region in availableRegions) {
      if (region.id == regionId) {
        return region.name;
      }
    }

    return null;
  }

  // Construeix un resum breu dels filtres actius.
  // Aquest text ajuda l’usuari a entendre ràpidament per què veu uns cims i no uns altres.
  String activeFiltersSummary(List<Region> availableRegions) {
    final parts = <String>[];

    final regionName = selectedRegionName(availableRegions);
    if (regionName != null && regionName.isNotEmpty) {
      parts.add(regionName);
    }

    if (minAltitude != null && maxAltitude != null) {
      parts.add('$minAltitude - $maxAltitude m');
    } else if (minAltitude != null) {
      parts.add('Des de $minAltitude m');
    } else if (maxAltitude != null) {
      parts.add('Fins a $maxAltitude m');
    }

    final statusFilterName = selectedStatusFilter.displayName;
    if (statusFilterName != null) {
      parts.add(statusFilterName);
    }

    if (hasActiveWeatherFilter) {
      final conditionLabels = weatherConditions
          .map((condition) => condition.displayLabel)
          .join(', ');
      final dayLabel = _weatherDayLabel();
      parts.add('$conditionLabels · $dayLabel');
    }

    return parts.join(' · ');
  }

  // Aquest mètode compon l'etiqueta del dia per al resum de filtres
  // actius. Pinta "Avui", "Demà" o el dia de la setmana en abreviatura
  // catalana segons la distància a avui, perquè el text quedi natural
  // sense haver de fer formatació de data al widget consumidor.
  String _weatherDayLabel() {
    final value = weatherDate;
    if (value == null || value.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate =
        DateTime(parsed.year, parsed.month, parsed.day);
    final diff = normalizedDate.difference(normalizedToday).inDays;
    if (diff == 0) return 'avui';
    if (diff == 1) return 'demà';
    const labels = ['dl', 'dt', 'dc', 'dj', 'dv', 'ds', 'dg'];
    final index = parsed.weekday - 1;
    if (index < 0 || index >= labels.length) {
      return value;
    }
    return labels[index];
  }
}
