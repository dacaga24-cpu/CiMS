import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra les opcions de filtre segons l’estat personal del cim.
// Permet veure només cims pendents, completats, objectius o preferits.
class PeaksStatusFilterSection extends StatelessWidget {
  const PeaksStatusFilterSection({
    super.key,
    required this.selectedStatusFilter,
    required this.onChanged,
  });

  // Aquestes propietats indiquen quin filtre està seleccionat
  // i comuniquen el canvi al panell principal.
  final PeakStatusFilter selectedStatusFilter;
  final ValueChanged<PeakStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estat personal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17212B),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusFilterChip(
              label: 'Tots',
              filter: PeakStatusFilter.none,
              selectedStatusFilter: selectedStatusFilter,
              onTap: onChanged,
            ),
            _StatusFilterChip(
              label: 'Pendents',
              filter: PeakStatusFilter.pending,
              selectedStatusFilter: selectedStatusFilter,
              onTap: onChanged,
            ),
            _StatusFilterChip(
              label: 'Completats',
              filter: PeakStatusFilter.completed,
              selectedStatusFilter: selectedStatusFilter,
              onTap: onChanged,
            ),
            _StatusFilterChip(
              label: 'Objectius',
              filter: PeakStatusFilter.target,
              selectedStatusFilter: selectedStatusFilter,
              onTap: onChanged,
            ),
            _StatusFilterChip(
              label: 'Preferits',
              filter: PeakStatusFilter.favorite,
              selectedStatusFilter: selectedStatusFilter,
              onTap: onChanged,
            ),
          ],
        ),
      ],
    );
  }
}

// Aquest widget intern representa una opció concreta del filtre d’estat.
// Manté un estil visual coherent per a totes les opcions seleccionables.
class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.filter,
    required this.selectedStatusFilter,
    required this.onTap,
  });

  final String label;
  final PeakStatusFilter filter;
  final PeakStatusFilter selectedStatusFilter;
  final ValueChanged<PeakStatusFilter> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedStatusFilter == filter;
    final color =
        isSelected ? const Color(0xFF0B57D0) : const Color(0xFFE5E7EB);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(filter),
      selectedColor: color.withValues(alpha: 0.14),
      backgroundColor: const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B57D0) : const Color(0xFF4B5563),
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: color,
      ),
    );
  }
}
