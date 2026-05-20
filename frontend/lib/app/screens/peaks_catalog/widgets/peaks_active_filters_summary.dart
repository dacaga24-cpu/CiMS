import 'package:flutter/material.dart';

// Aquest widget mostra un resum curt dels filtres actius.
// Ajuda l’usuari a entendre ràpidament per què el catàleg està limitat.
class PeaksActiveFiltersSummary extends StatelessWidget {
  const PeaksActiveFiltersSummary({
    super.key,
    required this.summary,
    required this.onClear,
  });

  // Aquestes propietats reben el text resumit dels filtres
  // i l’acció per eliminar-los des de la mateixa pantalla.
  final String summary;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Neteja'),
            ),
          ],
        ),
      ),
    );
  }
}
