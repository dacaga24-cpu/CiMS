import 'package:cims/app/screens/peaks_catalog/models/peak_sort_by.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_sort_order.dart';
import 'package:flutter/material.dart';

// Aquest panell permet escollir l’ordre del catàleg de cims.
// Cada opció combina un camp d’ordenació i un sentit concret.
class PeaksSortOrderSheet extends StatelessWidget {
  const PeaksSortOrderSheet({
    super.key,
    required this.sortBy,
    required this.sortOrder,
    required this.onSelected,
  });

  // Aquestes dades indiquen l’ordre actiu en el moment d’obrir el panell.
  // Permeten marcar visualment l’opció seleccionada.
  final PeakSortBy sortBy;
  final PeakSortOrder sortOrder;

  // Aquesta acció comunica al catàleg la nova ordenació seleccionada.
  final void Function(PeakSortBy sortBy, PeakSortOrder sortOrder) onSelected;

  // Aquest mètode obre el panell d’ordenació.
  // Rep l’estat actual i delega el canvi final a la pantalla que l’ha invocat.
  static Future<void> show(
    BuildContext context, {
    required PeakSortBy sortBy,
    required PeakSortOrder sortOrder,
    required void Function(PeakSortBy sortBy, PeakSortOrder sortOrder)
        onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return PeaksSortOrderSheet(
          sortBy: sortBy,
          sortOrder: sortOrder,
          onSelected: onSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ordena el catàleg',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF181A1F),
              ),
            ),
            const SizedBox(height: 16),
            _OptionRow(
              icon: Icons.arrow_downward_rounded,
              label: 'Altitud descendent',
              description: 'De més alt a més baix',
              isSelected:
                  sortBy == PeakSortBy.altitude &&
                  sortOrder == PeakSortOrder.descending,
              onTap: () => _select(
                context,
                PeakSortBy.altitude,
                PeakSortOrder.descending,
              ),
            ),
            _OptionRow(
              icon: Icons.arrow_upward_rounded,
              label: 'Altitud ascendent',
              description: 'De més baix a més alt',
              isSelected:
                  sortBy == PeakSortBy.altitude &&
                  sortOrder == PeakSortOrder.ascending,
              onTap: () => _select(
                context,
                PeakSortBy.altitude,
                PeakSortOrder.ascending,
              ),
            ),
            _OptionRow(
              icon: Icons.sort_by_alpha_rounded,
              label: 'Nom A → Z',
              description: 'Ordre alfabètic',
              isSelected:
                  sortBy == PeakSortBy.name &&
                  sortOrder == PeakSortOrder.ascending,
              onTap: () => _select(
                context,
                PeakSortBy.name,
                PeakSortOrder.ascending,
              ),
            ),
            _OptionRow(
              icon: Icons.sort_by_alpha_rounded,
              label: 'Nom Z → A',
              description: 'Ordre alfabètic invers',
              isSelected:
                  sortBy == PeakSortBy.name &&
                  sortOrder == PeakSortOrder.descending,
              onTap: () => _select(
                context,
                PeakSortBy.name,
                PeakSortOrder.descending,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Aquest mètode tanca el panell i comunica l’opció seleccionada.
  // Manté la pantalla principal com a responsable d’aplicar el canvi real.
  void _select(
    BuildContext context,
    PeakSortBy newSortBy,
    PeakSortOrder newSortOrder,
  ) {
    Navigator.of(context).pop();
    onSelected(newSortBy, newSortOrder);
  }
}

// Aquest widget representa una opció d’ordenació dins del panell.
// Mostra icona, títol, descripció i indicador visual quan està seleccionada.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  // Aquestes dades defineixen el contingut visual i l’acció de la fila.
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? const Color(0xFFEAF1FF) : Colors.transparent;
    final foregroundColor =
        isSelected ? const Color(0xFF0B57D0) : const Color(0xFF181A1F);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0B57D0),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}