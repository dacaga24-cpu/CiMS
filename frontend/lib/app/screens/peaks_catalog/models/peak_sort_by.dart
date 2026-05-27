// Aquest enum representa el camp pel qual s’ordena el catàleg de cims.
// Es combina amb l’ordre ascendent o descendent per construir la consulta al backend.
enum PeakSortBy {
  altitude,
  name,
}

extension PeakSortByX on PeakSortBy {
  // Aquest mètode retorna el valor que espera el backend com a paràmetre de consulta.
  // Manté el mapeig centralitzat perquè la UI no dupliqui aquests textos tècnics.
  String toQueryParam() {
    switch (this) {
      case PeakSortBy.altitude:
        return 'altitude';
      case PeakSortBy.name:
        return 'name';
    }
  }
}