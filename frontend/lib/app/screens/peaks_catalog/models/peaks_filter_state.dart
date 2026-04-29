import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/core/entity/region.dart';

// Aquest model concentra els filtres compartits entre el catàleg i el mapa.
// Permet evitar duplicar la mateixa lògica de regió, altitud i estat en dos controllers.
class PeaksFilterState {
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
  void apply({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    PeakStatusFilter statusFilter = PeakStatusFilter.none,
  }) {
    selectedRegionId = regionId;
    this.minAltitude = minAltitude;
    this.maxAltitude = maxAltitude;
    selectedStatusFilter = statusFilter;
  }

  // Reinicia tots els filtres i deixa la cerca sense restriccions addicionals.
  void clear() {
    selectedRegionId = null;
    minAltitude = null;
    maxAltitude = null;
    selectedStatusFilter = PeakStatusFilter.none;
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
