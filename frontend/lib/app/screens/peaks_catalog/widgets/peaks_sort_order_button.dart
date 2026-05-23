import 'package:cims/app/screens/peaks_catalog/models/peak_sort_by.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_sort_order.dart';
import 'package:flutter/material.dart';

// Radi compartit per Material, InkWell i Container. Sense aquesta
// constant es repetia tres vegades i un canvi d'estil obligava a tocar
// els tres llocs.
const BorderRadius _kBorderRadius = BorderRadius.all(Radius.circular(16));

// Aquest botó obre el bottom sheet que permet escollir el camp + sentit
// d'ordre del catàleg. La icona reflecteix la combinació activa (sortBy
// + sortOrder) perquè l'usuari pugui veure d'un cop d'ull com està
// ordenat el catàleg sense obrir el menú: fletxa amunt/avall per
// altituds, A-Z per nom.
class PeaksSortOrderButton extends StatelessWidget {
  const PeaksSortOrderButton({
    super.key,
    required this.sortBy,
    required this.sortOrder,
    required this.onTap,
    this.isLoading = false,
  });

  final PeakSortBy sortBy;
  final PeakSortOrder sortOrder;
  final VoidCallback onTap;

  // Indica que el catàleg encara està refrescant. Desactiva el toc
  // perquè polsacions repetides no acumulin peticions paral·leles al
  // backend mentre l'anterior encara no ha tornat.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Per fer un sol botó representi sempre la combinació activa, triem
    // la icona segons `sortBy` i el sentit segons `sortOrder`. Així la
    // capçalera del catàleg sempre comunica una idea clara: "ara estàs
    // veient X". El tooltip i el semanticsLabel afegeixen el text
    // complet per a accessibilitat.
    final iconData = _iconForSort(sortBy, sortOrder);
    final activeLabel = _activeLabel(sortBy, sortOrder);
    final tooltip = 'Ordena el catàleg. Ara: $activeLabel.';
    final semanticsLabel =
        'Obre el menú per ordenar el catàleg. Ara està ordenat per $activeLabel.';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: _kBorderRadius,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: _kBorderRadius,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: _kBorderRadius,
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Semantics(
              label: semanticsLabel,
              button: true,
              enabled: !isLoading,
              child: Icon(
                iconData,
                color: isLoading
                    ? const Color(0xFF9AA3B2)
                    : const Color(0xFF0B57D0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForSort(PeakSortBy by, PeakSortOrder order) {
    switch (by) {
      case PeakSortBy.altitude:
        return order == PeakSortOrder.descending
            ? Icons.arrow_downward
            : Icons.arrow_upward;
      case PeakSortBy.name:
        // A diferència de l'altitud (on Material té `arrow_upward` i
        // `arrow_downward` per distingir sentits), per a nom no hi ha
        // una variant clàssica per a "Z → A". Mantenim
        // `sort_by_alpha_rounded` per als dos sentits perquè comunica
        // "ordre alfabètic" amb claredat; la distinció A→Z vs Z→A es
        // delega al tooltip, al `semanticsLabel` i al check del sheet.
        return Icons.sort_by_alpha_rounded;
    }
  }

  String _activeLabel(PeakSortBy by, PeakSortOrder order) {
    switch (by) {
      case PeakSortBy.altitude:
        return order == PeakSortOrder.descending
            ? 'altitud descendent'
            : 'altitud ascendent';
      case PeakSortBy.name:
        return order == PeakSortOrder.ascending ? 'nom A → Z' : 'nom Z → A';
    }
  }
}
