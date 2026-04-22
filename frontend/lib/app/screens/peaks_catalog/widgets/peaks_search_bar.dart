import 'package:flutter/material.dart';

// Aquest widget encapsula la barra de cerca del catàleg.
// També mostra el botó per obrir el panell de filtres.
class PeaksSearchBar extends StatelessWidget {
  const PeaksSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  // Aquestes propietats connecten el widget amb l’estat extern de la pantalla,
  // permetent gestionar el text escrit, els canvis de cerca i l’obertura dels filtres.
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    // Aquest bloc construeix la capçalera de cerca del catàleg.
    // Combina el camp de text amb un botó lateral que reflecteix visualment
    // si hi ha filtres actius en aquell moment.
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cerca cims...',
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

        // Aquest botó obre el panell de filtres i canvia lleugerament d’aspecte
        // quan el catàleg ja té filtres aplicats, per fer-ho visible a l’usuari.
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