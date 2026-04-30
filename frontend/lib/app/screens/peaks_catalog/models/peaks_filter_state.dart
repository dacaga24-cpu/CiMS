import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/core/entity/region.dart';
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

  // Indica si hi ha algun filtre aplicat.
  // La UI ho utilitza per mostrar o ocultar el resum de filtres.
  bool get hasActiveFilters =>
      selectedRegionId != null ||
      minAltitude != null ||
      maxAltitude != null ||
      selectedStatusFilter != PeakStatusFilter.none;

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
  }) {
    final changed = selectedRegionId != regionId ||
        this.minAltitude != minAltitude ||
        this.maxAltitude != maxAltitude ||
        selectedStatusFilter != statusFilter;

    selectedRegionId = regionId;
    this.minAltitude = minAltitude;
    this.maxAltitude = maxAltitude;
    selectedStatusFilter = statusFilter;

    if (changed) {
      notifyListeners();
    }
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
    if (wasActive) {
      notifyListeners();
    }
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

    return parts.join(' · ');
  }
}
