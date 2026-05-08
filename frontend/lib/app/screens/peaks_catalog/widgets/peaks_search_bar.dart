import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Defineix la longitud màxima acceptada al cercador de cims.
// El valor s'alinea amb la mida màxima del nom del cim a la base de dades.
const int peakSearchMaxLength = 150;

// Aquest widget mostra la barra de cerca compartida pel catàleg i el mapa.
// També inclou el botó que obre el panell de filtres.
class PeaksSearchBar extends StatelessWidget {
  const PeaksSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  // Aquestes propietats connecten el camp de cerca amb la pantalla que l'utilitza.
  // Permeten controlar el text escrit, reaccionar als canvis i obrir els filtres.
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            inputFormatters: [
              LengthLimitingTextInputFormatter(peakSearchMaxLength),
            ],
            decoration: const InputDecoration(
              hintText: 'Cerca cims...',
              counterText: '',
              prefixIcon: Icon(
                Icons.search,
                color: Color(0xFF0B57D0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: hasActiveFilters
              ? const Color(0xFFE8F0FE)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasActiveFilters
                      ? const Color(0xFF0B57D0)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              child: Icon(
                Icons.tune,
                color: hasActiveFilters
                    ? const Color(0xFF0B57D0)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ],
    );
  }
}