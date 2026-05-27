// Aquest enum representa el sentit d’ordenació del catàleg.
// Es combina amb el camp d’ordenació per construir la consulta al backend.
enum PeakSortOrder {
  ascending,
  descending,
}

extension PeakSortOrderX on PeakSortOrder {
  // Aquest mètode retorna el valor que espera el backend com a paràmetre de consulta.
  // Manté el mapeig centralitzat perquè la UI no dupliqui aquests textos tècnics.
  String toQueryParam() {
    switch (this) {
      case PeakSortOrder.ascending:
        return 'asc';
      case PeakSortOrder.descending:
        return 'desc';
    }
  }
}