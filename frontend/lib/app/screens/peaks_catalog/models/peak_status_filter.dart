import 'package:cims/core/entity/peak_status.dart';

// Aquest enum defineix els filtres disponibles segons l’estat personal del cim.
// S’utilitza des del catàleg, el mapa i el panell de filtres per mantenir
// les opcions d’estat separades dels controllers.
enum PeakStatusFilter {
  none,
  pending,
  completed,
  target,
  favorite,
}

// Aquesta extensió centralitza el text visible i la comparació dels filtres d’estat.
// Així el catàleg i el mapa no han de duplicar el mateix switch.
extension PeakStatusFilterX on PeakStatusFilter {
  // Retorna el nom que es mostra a la interfície per al filtre seleccionat.
  String? get displayName {
    switch (this) {
      case PeakStatusFilter.none:
        return null;
      case PeakStatusFilter.pending:
        return 'Pendents';
      case PeakStatusFilter.completed:
        return 'Completats';
      case PeakStatusFilter.target:
        return 'Objectius';
      case PeakStatusFilter.favorite:
        return 'Preferits';
    }
  }

  // Comprova si l’estat d’un cim compleix el filtre actual.
  // Si no hi ha filtre, el cim sempre es considera vàlid.
  bool matches(PeakStatus? status) {
    switch (this) {
      case PeakStatusFilter.none:
        return true;
      case PeakStatusFilter.pending:
        return !(status?.isCompleted ?? false);
      case PeakStatusFilter.completed:
        return status?.isCompleted ?? false;
      case PeakStatusFilter.target:
        return status?.isTarget ?? false;
      case PeakStatusFilter.favorite:
        return status?.isFavorite ?? false;
    }
  }
}
