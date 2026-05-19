import 'package:flutter/material.dart';

// Aquest widget mostra un missatge quan el catàleg no té resultats.
// El text s’adapta segons si hi ha cerca, filtres o cap dada disponible.
class PeaksEmptyState extends StatelessWidget {
  const PeaksEmptyState({
    super.key,
    required this.currentSearch,
    required this.hasActiveFilters,
  });

  // Aquestes propietats permeten ajustar el missatge segons el context
  // en què el catàleg ha quedat sense resultats.
  final String currentSearch;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final hasSearch = currentSearch.isNotEmpty;

    String message = 'Encara no hi ha cims disponibles';

    if (hasSearch && hasActiveFilters) {
      message = 'No s\'han trobat cims amb aquesta cerca i aquests filtres';
    } else if (hasSearch) {
      message = 'No s\'han trobat cims per a aquesta cerca';
    } else if (hasActiveFilters) {
      message = 'No s\'han trobat cims amb els filtres aplicats';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(
              Icons.landscape_outlined,
              size: 44,
              color: Color(0xFF9AA3B2),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
