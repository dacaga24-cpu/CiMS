import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_altitude_range_fields.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_filters_actions.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_region_filter_field.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_status_filter_section.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:cims/core/entity/region.dart';
import 'package:flutter/material.dart';

// Aquest panell mostra els filtres disponibles del catàleg de cims.
// Permet seleccionar comarca, rang d’altitud i estat personal del cim.
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

  // Aquestes dades defineixen les opcions disponibles i els valors inicials del panell.
  // També exposen les accions per aplicar o netejar els filtres.
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
  late final TextEditingController _minAltitudeController;
  late final TextEditingController _maxAltitudeController;

  int? _selectedRegionId;
  late PeakStatusFilter _selectedStatusFilter;

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

    _minAltitudeController.addListener(_handleAltitudeChanged);
    _maxAltitudeController.addListener(_handleAltitudeChanged);
  }

  // Aquest mètode refresca el panell quan canvien els camps d’altitud.
  // Permet mostrar o amagar la validació del rang en temps real.
  void _handleAltitudeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // Aquest mètode transforma el text d’altitud en un valor numèric opcional.
  // Si el camp està buit o no és vàlid, no aplica cap límit.
  int? _parseAltitude(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    return int.tryParse(trimmedValue);
  }

  // Aquest getter indica si el rang d’altitud seleccionat és incoherent.
  // Evita aplicar filtres amb una altura mínima superior a la màxima.
  bool get _hasInvalidAltitudeRange {
    final minAltitude = _parseAltitude(_minAltitudeController.text);
    final maxAltitude = _parseAltitude(_maxAltitudeController.text);

    if (minAltitude == null || maxAltitude == null) {
      return false;
    }

    return minAltitude > maxAltitude;
  }

  // Aquest mètode neteja tots els filtres del panell.
  // Després tanca el panell i comunica la neteja a la pantalla principal.
  Future<void> _handleClear() async {
    _minAltitudeController.clear();
    _maxAltitudeController.clear();

    setState(() {
      _selectedRegionId = null;
      _selectedStatusFilter = PeakStatusFilter.none;
    });

    final onClear = widget.onClear;

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onClear();
    });
  }

  // Aquest mètode aplica els filtres seleccionats.
  // Tanca el panell abans de comunicar els valors finals a la pantalla principal.
  void _handleApply() {
    if (_hasInvalidAltitudeRange) {
      return;
    }

    final minAltitude = _parseAltitude(_minAltitudeController.text);
    final maxAltitude = _parseAltitude(_maxAltitudeController.text);
    final selectedRegionId = _selectedRegionId;
    final selectedStatusFilter = _selectedStatusFilter;
    final onApply = widget.onApply;

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onApply(
        regionId: selectedRegionId,
        minAltitude: minAltitude,
        maxAltitude: maxAltitude,
        statusFilter: selectedStatusFilter,
      );
    });
  }

  // Aquest mètode allibera els controladors dels camps d’altitud.
  @override
  void dispose() {
    _minAltitudeController.removeListener(_handleAltitudeChanged);
    _maxAltitudeController.removeListener(_handleAltitudeChanged);
    _minAltitudeController.dispose();
    _maxAltitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInvalidAltitudeRange = _hasInvalidAltitudeRange;
    final isCompact = AppResponsive.isCompact(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Align(
          alignment: isCompact ? Alignment.bottomCenter : Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isCompact ? double.infinity : 620,
            ),
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
                      if (hasInvalidAltitudeRange) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'L\'altura mínima no pot ser superior a l\'altura màxima.',
                          style: TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                        canApply: !hasInvalidAltitudeRange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}