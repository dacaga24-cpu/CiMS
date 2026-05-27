import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/core/entity/region.dart';
import 'package:flutter/foundation.dart';

// Aquest model concentra els filtres compartits entre el catàleg i el mapa.
// Manté una única instància perquè totes dues pantalles treballin amb el mateix estat.
class PeaksFilterState extends ChangeNotifier {
  PeaksFilterState._();

  // Aquesta instància compartida viu durant tot el cicle de vida de l’aplicació.
  // Els controllers interessats s’hi subscriuen per reaccionar als canvis de filtre.
  static final PeaksFilterState shared = PeaksFilterState._();

  // Aquestes dades representen els filtres que l’usuari pot aplicar sobre els cims.
  int? selectedRegionId;
  int? minAltitude;
  int? maxAltitude;
  PeakStatusFilter selectedStatusFilter = PeakStatusFilter.none;

  // Aquest getter indica si hi ha algun filtre actiu.
  // Permet mostrar o ocultar el resum de filtres a la interfície.
  bool get hasActiveFilters =>
      selectedRegionId != null ||
      minAltitude != null ||
      maxAltitude != null ||
      selectedStatusFilter != PeakStatusFilter.none;

  // Aquest mètode aplica els filtres escollits per l’usuari.
  // Només notifica canvis si algun valor és diferent per evitar recàrregues innecessàries.
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

  // Aquest mètode elimina tots els filtres aplicats.
  // Si ja no hi havia cap filtre actiu, evita notificar canvis innecessaris.
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

  // Aquest mètode retorna el nom de la regió seleccionada.
  // Permet mostrar un resum entenedor a partir de l’identificador guardat.
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

  // Aquest mètode construeix un resum breu dels filtres actius.
  // Ajuda l’usuari a entendre per què es mostren uns cims concrets.
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