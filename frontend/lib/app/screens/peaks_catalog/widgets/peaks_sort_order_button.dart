import 'package:cims/app/screens/peaks_catalog/models/peak_sort_by.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_sort_order.dart';
import 'package:flutter/material.dart';

// Aquest radi compartit manté la mateixa forma visual en totes les capes del botó.
// Evita repetir el mateix valor en Material, InkWell i Container.
const BorderRadius _kBorderRadius = BorderRadius.all(Radius.circular(16));

// Aquest botó obre el panell d’ordenació del catàleg.
// La icona mostra de manera resumida quin criteri d’ordre hi ha actiu.
class PeaksSortOrderButton extends StatelessWidget {
  const PeaksSortOrderButton({
    super.key,
    required this.sortBy,
    required this.sortOrder,
    required this.onTap,
    this.isLoading = false,
  });

  // Aquestes dades defineixen el criteri d’ordenació actual i l’acció del botó.
  final PeakSortBy sortBy;
  final PeakSortOrder sortOrder;
  final VoidCallback onTap;

  // Aquest valor indica si el catàleg està carregant.
  // Quan és cert, el botó queda desactivat per evitar peticions duplicades.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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

  // Aquest mètode selecciona la icona segons el camp i el sentit d’ordenació.
  // Permet comunicar visualment si l’ordre actual és per altitud o per nom.
  IconData _iconForSort(PeakSortBy by, PeakSortOrder order) {
    switch (by) {
      case PeakSortBy.altitude:
        return order == PeakSortOrder.descending
            ? Icons.arrow_downward
            : Icons.arrow_upward;
      case PeakSortBy.name:
        return Icons.sort_by_alpha_rounded;
    }
  }

  // Aquest mètode genera el text descriptiu de l’ordre actiu.
  // S’utilitza en el tooltip i en l’etiqueta d’accessibilitat.
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