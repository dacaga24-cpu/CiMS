import 'package:cims/app/screens/user_stats/user_stats_controller.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el selector temporal de la pantalla d’estadístiques.
// Permet canviar el rang de lectura de mètriques variables com els metres totals.
class StatsRangeSelector extends StatelessWidget {
  const StatsRangeSelector({
    super.key,
    required this.options,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  // Aquestes dades defineixen les opcions disponibles, el rang actiu
  // i l’acció que es comunica al controller quan l’usuari canvia el filtre.
  final List<UserStatsRangeOption> options;
  final String selectedRange;
  final ValueChanged<String> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedRange;

          return _StatsRangeChip(
            label: option.label,
            isSelected: isSelected,
            onTap: () => onRangeSelected(option.value),
          );
        },
      ),
    );
  }
}

// Aquest element representa una opció individual del selector temporal.
// Canvia d’aspecte quan és el rang actiu per deixar clar quin període s’aplica.
class _StatsRangeChip extends StatelessWidget {
  const _StatsRangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? const Color(0xFF0B57D0) : Colors.white;

    final foregroundColor =
        isSelected ? Colors.white : const Color(0xFF475467);

    final borderColor = isSelected
        ? const Color(0xFF0B57D0)
        : const Color(0xFFE4E7EC);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0B57D0).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}