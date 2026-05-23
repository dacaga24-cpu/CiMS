// Aquest enum representa el sentit d'ordre del catàleg. Va aparellat
// sempre amb `PeakSortBy` (altitud/nom): la combinació dels dos és
// l'única manera vàlida d'expressar l'ordre. És estat local del
// controller del catàleg (no es comparteix amb el mapa, perquè
// l'ordre no afecta visualment el mapa). Es manté com a font de
// veritat única perquè els mapejos a query param no es dupliquin a la UI.
enum PeakSortOrder {
  // En altitud: de més baix a més alt. En nom: A → Z.
  ascending,
  // En altitud: de més alt a més baix (default, manté el comportament
  // històric "Pica d'Estats primer"). En nom: Z → A.
  descending,
}

extension PeakSortOrderX on PeakSortOrder {
  // Retorna el valor que cal enviar al backend com a query param
  // `sortOrder`. Coincideix amb la whitelist del servei
  // (`ALLOWED_PEAK_SORT_ORDERS`); qualsevol divergència aquí
  // provocaria un 400.
  String toQueryParam() {
    switch (this) {
      case PeakSortOrder.ascending:
        return 'asc';
      case PeakSortOrder.descending:
        return 'desc';
    }
  }
}
