import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:cims/core/entity/region.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el panell de filtres del catàleg.
// S’obre com un bottom sheet i permet filtrar per comarca
// i per rang d’altura sense perdre de vista el llistat del darrere.
class PeaksFiltersSheet extends StatefulWidget {
  const PeaksFiltersSheet({
    super.key,
    required this.availableRegions,
    required this.initialRegionId,
    required this.initialMinAltitude,
    required this.initialMaxAltitude,
    required this.onApply,
    required this.onClear,
  });

  // Aquestes propietats reben les dades disponibles i l’estat inicial dels filtres
  // perquè el panell es pugui obrir mostrant la configuració actual del catàleg.
  final List<Region> availableRegions;
  final int? initialRegionId;
  final int? initialMinAltitude;
  final int? initialMaxAltitude;
  final void Function({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  }) onApply;
  final Future<void> Function() onClear;

  @override
  State<PeaksFiltersSheet> createState() => _PeaksFiltersSheetState();
}

class _PeaksFiltersSheetState extends State<PeaksFiltersSheet> {
  // Aquests controladors mantenen el contingut dels camps d’altura
  // mentre l’usuari interactua amb el formulari.
  late final TextEditingController _minAltitudeController;
  late final TextEditingController _maxAltitudeController;

  // Aquesta variable guarda la comarca seleccionada dins del panell.
  int? _selectedRegionId;

  @override
  void initState() {
    super.initState();
    _selectedRegionId = widget.initialRegionId;
    _minAltitudeController = TextEditingController(
      text: widget.initialMinAltitude?.toString() ?? '',
    );
    _maxAltitudeController = TextEditingController(
      text: widget.initialMaxAltitude?.toString() ?? '',
    );
  }

  // Aquest mètode converteix el text introduït en una altura numèrica.
  // Si el camp està buit o no és vàlid, retorna null per indicar que no s’aplica aquest filtre.
  int? _parseAltitude(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    return int.tryParse(trimmedValue);
  }

  // Aquest mètode reinicia tots els filtres visibles del panell i executa
  // l’acció externa de neteja perquè el catàleg torni al seu estat general.
  Future<void> _handleClear() async {
    _minAltitudeController.clear();
    _maxAltitudeController.clear();
    setState(() {
      _selectedRegionId = null;
    });

    await widget.onClear();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Aquest mètode recull els valors seleccionats, els prepara en un format útil
  // i els envia a la pantalla principal perquè actualitzi el catàleg filtrat.
  void _handleApply() {
    final minAltitude = _parseAltitude(_minAltitudeController.text);
    final maxAltitude = _parseAltitude(_maxAltitudeController.text);

    widget.onApply(
      regionId: _selectedRegionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _minAltitudeController.dispose();
    _maxAltitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Aquesta construcció mostra el full inferior amb el formulari de filtres,
    // mantenint una presentació clara i adaptada al teclat quan apareix.
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filtres',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Aquest desplegable permet filtrar el catàleg per comarca.
                  // L’estil visual principal ja s’hereta del tema global de l’aplicació.
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedRegionId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Totes les comarques'),
                      ),
                      ...widget.availableRegions.map(
                        (region) => DropdownMenuItem<int?>(
                          value: region.id,
                          child: Text(region.name),
                        ),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Comarca',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedRegionId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Aquest bloc mostra el rang d’altura mínim i màxim.
                  // Els camps mantenen l’estil comú dels formularis gràcies a l’AppTheme.
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAltitudeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Altura mínima',
                            suffixText: 'm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxAltitudeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Altura màxima',
                            suffixText: 'm',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Aquest bloc mostra les accions principals del panell:
                  // netejar filtres o aplicar-los al catàleg.
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryPillButton(
                          label: 'Neteja',
                          onPressed: _handleClear,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryGradientButton(
                          label: 'Aplica',
                          onPressed: _handleApply,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}