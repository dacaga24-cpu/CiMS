import 'package:flutter/material.dart';

// Aquest widget representa la barra de cerca visual del catàleg.
// Es manté com a component separat perquè forma part de la capçalera
// i molt probablement creixerà quan s’hi afegeixin filtres i accions reals.
class PeaksSearchBar extends StatelessWidget {
  const PeaksSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  // Aquest mètode construeix la barra superior del catàleg amb dos elements:
  // el camp de cerca principal i el botó reservat per als futurs filtres.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Aquest bloc mostra el camp on l’usuari pot escriure una cerca.
        // El text introduït s’envia cap a fora perquè la pantalla decideixi com filtrar el catàleg.
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Cerca cims...',
                hintStyle: TextStyle(
                  color: Color(0xFFB0B3B8),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFFA0A7B4),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Aquest botó deixa preparada l’entrada als filtres del catàleg.
        // Encara que la funcionalitat no estigui completa, el component ja queda previst dins del disseny.
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: IconButton(
            onPressed: onFilterTap,
            icon: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF5E6B80),
            ),
          ),
        ),
      ],
    );
  }
}
