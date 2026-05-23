// Aquest enum representa el camp pel qual s'ordena el catàleg.
// Va aparellat amb `PeakSortOrder` (asc/desc): la combinació dels dos
// és l'única manera vàlida d'expressar l'ordre. Els dos viuen com a
// estat local del controller del catàleg; es mantenen aquí com a font
// de veritat única perquè els mapejos a query param i a textos visibles
// no es dupliquin per la UI.
enum PeakSortBy {
  // Per altitud. Combinat amb `descending` és el comportament històric
  // (Pica d'Estats primer); combinat amb `ascending` mostra primer els
  // cims més baixos.
  altitude,
  // Per nom. Combinat amb `ascending` dona A → Z; amb `descending` Z → A.
  name,
}

extension PeakSortByX on PeakSortBy {
  // Retorna el valor que cal enviar al backend com a query param
  // `sortBy`. Coincideix amb la whitelist del servei
  // (`ALLOWED_PEAK_SORT_BY`); qualsevol divergència aquí provocaria un 400.
  String toQueryParam() {
    switch (this) {
      case PeakSortBy.altitude:
        return 'altitude';
      case PeakSortBy.name:
        return 'name';
    }
  }
}
