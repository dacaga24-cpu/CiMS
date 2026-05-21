import 'package:cims/app/screens/peaks_catalog/models/peak_sort_order.dart';
import 'package:flutter/material.dart';

// Radi compartit per Material, InkWell i Container. Sense aquesta
// constant es repetia tres vegades i un canvi d'estil obligava a tocar
// els tres llocs.
const BorderRadius _kBorderRadius = BorderRadius.all(Radius.circular(16));

// Aquest botó alterna l'ordre d'altitud del catàleg. La icona reflecteix
// l'ordre ACTIU (no l'ordre que s'aplicarà si es prem), igual que fan
// les capçaleres de columna de qualsevol taula amb sort: l'usuari veu
// "ara mateix és de més alt a més baix" i tocant inverteix.
class PeaksSortOrderButton extends StatelessWidget {
  const PeaksSortOrderButton({
    super.key,
    required this.sortOrder,
    required this.onTap,
    this.isLoading = false,
  });

  final PeakSortOrder sortOrder;
  final VoidCallback onTap;

  // Indica que el catàleg encara està refrescant. Desactiva el toc
  // perquè polsacions repetides no acumulin peticions paral·leles al
  // backend mentre l'anterior encara no ha tornat.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDescending = sortOrder == PeakSortOrder.descending;
    // Tant el tooltip com la `semanticsLabel` segueixen el patró
    // d'accessibilitat per a buttons toggle: anunciar primer l'acció
    // que es farà (verb), i després l'estat actual. Així l'usuari amb
    // screen reader sap què passarà al tocar enlloc d'haver d'inferir-ho
    // d'un "ara descendent" ambigu.
    final tooltip = isDescending
        ? 'Inverteix l\'ordre. Ara: més alts primer.'
        : 'Inverteix l\'ordre. Ara: més baixos primer.';
    final semanticsLabel = isDescending
        ? 'Inverteix l\'ordre del catàleg. Ara per altitud descendent.'
        : 'Inverteix l\'ordre del catàleg. Ara per altitud ascendent.';

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
                isDescending ? Icons.arrow_downward : Icons.arrow_upward,
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
}
