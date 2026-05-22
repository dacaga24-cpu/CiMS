// Aquest enum representa l'ordre d'altitud aplicat al catàleg de cims.
// És un estat local del controller del catàleg (no es comparteix amb el
// mapa, perquè l'ordre no afecta visualment el mapa). Es manté com a
// font de veritat única perquè els mapejos a query param i a títols
// visibles no es duplique en a la UI.
enum PeakSortOrder {
  // Des de més baix a més alt: 80 m → 3.143 m.
  ascending,
  // Des de més alt a més baix (per defecte): 3.143 m → 80 m.
  // Coincideix amb el comportament històric del backend (`ORDER BY
  // altitude DESC`) per no canviar la primera impressió que té
  // l'usuari quan obre el catàleg per primera vegada.
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

  // Retorna l'ordre oposat. S'usa des del botó toggle del header
  // perquè cada toc alterni entre ascendent i descendent sense que la
  // UI hagi de conèixer els valors concrets.
  PeakSortOrder toggled() {
    switch (this) {
      case PeakSortOrder.ascending:
        return PeakSortOrder.descending;
      case PeakSortOrder.descending:
        return PeakSortOrder.ascending;
    }
  }
}
