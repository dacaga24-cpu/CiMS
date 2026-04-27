import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_altitude_range_fields.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_filters_actions.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_region_filter_field.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_status_filter_section.dart';
import 'package:cims/core/entity/region.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el panell de filtres del catàleg.
// S’obre com un bottom sheet i permet filtrar per comarca,
// rang d’altitud i estat personal sense perdre de vista el llistat del darrere.
class PeaksFiltersSheet extends StatefulWidget {
  const PeaksFiltersSheet({
    super.key,
    required this.availableRegions,
    required this.initialRegionId,
    required this.initialMinAltitude,
    required this.initialMaxAltitude,
    required this.initialStatusFilter,
    required this.onApply,
    required this.onClear,
  });

  // Aquestes propietats reben les dades disponibles i l’estat inicial dels filtres
  // perquè el panell es pugui obrir mostrant la configuració actual del catàleg.
  final List<Region> availableRegions;
  final int? initialRegionId;
  final int? initialMinAltitude;
  final int? initialMaxAltitude;
  final PeakStatusFilter initialStatusFilter;
  final void Function({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    PeakStatusFilter statusFilter,
  }) onApply;
  final Future<void> Function() onClear;

  @override
  State<PeaksFiltersSheet> createState() => _PeaksFiltersSheetState();
}

class _PeaksFiltersSheetState extends State<PeaksFiltersSheet> {
  // Aquests controladors mantenen el contingut dels camps d’altitud
  // mentre l’usuari interactua amb el formulari.
  late final TextEditingController _minAltitudeController;
  late final TextEditingController _maxAltitudeController;

  // Aquestes variables guarden els filtres seleccionats dins del panell.
  int? _selectedRegionId;
  late PeakStatusFilter _selectedStatusFilter;

  // Aquest mètode prepara el panell amb els filtres que ja estaven aplicats.
  // Així l’usuari pot veure i modificar la configuració actual sense perdre-la.
  @override
  void initState() {
    super.initState();
    _selectedRegionId = widget.initialRegionId;
    _selectedStatusFilter = widget.initialStatusFilter;
    _minAltitudeController = TextEditingController(
      text: widget.initialMinAltitude?.toString() ?? '',
    );
    _maxAltitudeController = TextEditingController(
      text: widget.initialMaxAltitude?.toString() ?? '',
    );
  }

  // Aquest mètode converteix el text introduït en una altitud numèrica.
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
      _selectedStatusFilter = PeakStatusFilter.none;
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
      statusFilter: _selectedStatusFilter,
    );

    Navigator.of(context).pop();
  }

  // Aquest mètode allibera els controladors dels camps quan es tanca el panell.
  // Evita mantenir recursos actius que ja no són necessaris.
  @override
  void dispose() {
    _minAltitudeController.dispose();
    _maxAltitudeController.dispose();
    super.dispose();
  }

  // Aquest mètode construeix el contingut visual del panell de filtres.
  // Agrupa els filtres per comarca, altitud i estat personal en un únic formulari.
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
              child: SingleChildScrollView(
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
                    PeaksRegionFilterField(
                      availableRegions: widget.availableRegions,
                      selectedRegionId: _selectedRegionId,
                      onChanged: (value) {
                        setState(() {
                          _selectedRegionId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    PeaksAltitudeRangeFields(
                      minAltitudeController: _minAltitudeController,
                      maxAltitudeController: _maxAltitudeController,
                    ),
                    const SizedBox(height: 20),
                    PeaksStatusFilterSection(
                      selectedStatusFilter: _selectedStatusFilter,
                      onChanged: (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    PeaksFiltersActions(
                      onClear: _handleClear,
                      onApply: _handleApply,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}