import 'package:cims/core/entity/region.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el desplegable de comarques del panell de filtres.
// Permet seleccionar una comarca concreta o tornar a mostrar-les totes.
class PeaksRegionFilterField extends StatelessWidget {
  const PeaksRegionFilterField({
    super.key,
    required this.availableRegions,
    required this.selectedRegionId,
    required this.onChanged,
  });

  // Aquest bloc rep les comarques disponibles, la comarca seleccionada
  // i l’acció que actualitza el filtre quan l’usuari canvia la selecció.
  final List<Region> availableRegions;
  final int? selectedRegionId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedRegionId,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Totes les comarques'),
        ),
        ...availableRegions.map(
          (region) => DropdownMenuItem<int?>(
            value: region.id,
            child: Text(region.name),
          ),
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Comarca',
      ),
      onChanged: onChanged,
    );
  }
}