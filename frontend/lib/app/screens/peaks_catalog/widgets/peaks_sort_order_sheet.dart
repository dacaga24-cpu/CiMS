import 'package:cims/app/screens/peaks_catalog/models/peak_sort_by.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_sort_order.dart';
import 'package:flutter/material.dart';

// Aquest bottom sheet permet escollir la combinació de camp + sentit que
// ordena el catàleg. Visualment cada opció es marca amb un check, però
// lògicament són exclusives entre si: només una pot estar activa alhora,
// així que escollir-ne una neteja les altres. Aquest model evita estats
// contradictoris com "A → Z" i "Z → A" actius al mateix temps.
//
// El sheet retorna immediatament en tocar una opció: no hi ha botó
// "Aplicar". Així el feedback és directe i l'usuari pot reobrir-lo si
// es vol equivocar i corregir; sense un botó d'aplicació evitem un pas
// addicional que no aporta valor en aquest cas (només 4 opcions, sense
// configuració extra que justifiqui un commit explícit).
class PeaksSortOrderSheet extends StatelessWidget {
  const PeaksSortOrderSheet({
    super.key,
    required this.sortBy,
    required this.sortOrder,
    required this.onSelected,
  });

  // Camp d'ordre actiu en aquest moment. Serveix per marcar visualment
  // l'opció seleccionada amb un check.
  final PeakSortBy sortBy;

  // Sentit d'ordre actiu (asc/desc). Combinat amb `sortBy` identifica
  // de manera única una de les 4 opcions del menú.
  final PeakSortOrder sortOrder;

  // Callback que executa el caller quan l'usuari escull una nova
  // combinació. El sheet es tanca automàticament abans de cridar.
  final void Function(PeakSortBy sortBy, PeakSortOrder sortOrder) onSelected;

  // Helper que obre el sheet i retorna un Future que es resol quan
  // l'usuari el tanca (per gest o per selecció). Manté els valors actuals
  // i delega la lògica del canvi al `onSelected` que passa el caller.
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

  // Tanca el sheet abans de notificar el caller. Així evitem que el
  // caller hagi de pensar en l'estat del sheet ni que un pop tardà
  // arribi quan el catàleg ja s'ha refrescat.
  void _select(
    BuildContext context,
    PeakSortBy newSortBy,
    PeakSortOrder newSortOrder,
  ) {
    Navigator.of(context).pop();
    onSelected(newSortBy, newSortOrder);
  }
}

// Cada fila del menú representa una de les 4 combinacions. Quan està
// seleccionada es mostra el check a la dreta i el fons s'omple de blau
// suau per donar feedback visual immediat. El callback no s'amaga
// quan està seleccionada perquè reseleccionar la mateixa opció és
// inofensiu (el controller ho ignora) i permet a l'usuari tancar el
// sheet tocant la opció activa.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

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
