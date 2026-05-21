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

  // Retorna el valor que cal enviar al backend com a query param `status`.
  // L'enum guarda noms en català per al display, però l'API espera els
  // mateixos identificadors que el camp de la taula `peak_status`.
  String? toQueryParam() {
    switch (this) {
      case PeakStatusFilter.none:
        return null;
      case PeakStatusFilter.pending:
        return 'pending';
      case PeakStatusFilter.completed:
        return 'completed';
      case PeakStatusFilter.target:
        return 'target';
      case PeakStatusFilter.favorite:
        return 'favorite';
    }
  }
}
