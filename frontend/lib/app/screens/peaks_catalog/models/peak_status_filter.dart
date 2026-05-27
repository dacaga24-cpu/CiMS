// Aquest enum defineix els filtres disponibles segons l’estat personal del cim.
// S’utilitza al catàleg, al mapa i al panell de filtres.
enum PeakStatusFilter {
  none,
  pending,
  completed,
  target,
  favorite,
}

// Aquesta extensió centralitza el text visible i el valor tècnic de cada filtre.
// Evita duplicar la mateixa conversió en diferents pantalles.
extension PeakStatusFilterX on PeakStatusFilter {
  // Aquest getter retorna el nom que es mostra a la interfície.
  // El filtre sense selecció no mostra cap etiqueta específica.
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

  // Aquest mètode retorna el valor que espera el backend com a paràmetre de consulta.
  // Manté el mapeig centralitzat perquè catàleg i mapa utilitzin el mateix criteri.
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