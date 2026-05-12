import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_altitude_range_fields.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_filters_actions.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_region_filter_field.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_status_filter_section.dart';
import 'package:cims/app/screens/peaks_catalog/widgets/peaks_weather_filter_section.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/entity/weather_condition.dart';
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
    required this.initialWeatherDate,
    required this.initialWeatherConditions,
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
  final String? initialWeatherDate;
  final Set<WeatherConditionType> initialWeatherConditions;
  final void Function({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    PeakStatusFilter statusFilter,
    String? weatherDate,
    Set<WeatherConditionType> weatherConditions,
  }) onApply;
  final Future<void> Function() onClear;

  @override
  State<PeaksFiltersSheet> createState() => _PeaksFiltersSheetState();
}

// Aquesta classe gestiona l’estat temporal del panell de filtres.
// Manté els valors seleccionats mentre el modal està obert i comunica els canvis a la pantalla principal.
class _PeaksFiltersSheetState extends State<PeaksFiltersSheet> {
  // Aquests controladors mantenen el contingut dels camps d’altitud
  // mentre l’usuari interactua amb el formulari.
  late final TextEditingController _minAltitudeController;
  late final TextEditingController _maxAltitudeController;

  // Aquestes variables guarden els filtres seleccionats dins del panell.
  int? _selectedRegionId;
  late PeakStatusFilter _selectedStatusFilter;
  String? _selectedWeatherDate;
  late Set<WeatherConditionType> _selectedWeatherConditions;

  // Aquest mètode prepara el panell amb els filtres que ja estaven aplicats.
  // Així l’usuari pot veure i modificar la configuració actual sense perdre-la.
  @override
  void initState() {
    super.initState();
    _selectedRegionId = widget.initialRegionId;
    _selectedStatusFilter = widget.initialStatusFilter;
    _selectedWeatherDate = widget.initialWeatherDate;
    _selectedWeatherConditions =
        Set<WeatherConditionType>.from(widget.initialWeatherConditions);
    _minAltitudeController = TextEditingController(
      text: widget.initialMinAltitude?.toString() ?? '',
    );
    _maxAltitudeController = TextEditingController(
      text: widget.initialMaxAltitude?.toString() ?? '',
    );

    _minAltitudeController.addListener(_handleAltitudeChanged);
    _maxAltitudeController.addListener(_handleAltitudeChanged);
  }

  // Aquest mètode actualitza el panell quan canvien les altures.
  // Permet mostrar l’avís d’error i bloquejar l’aplicació de filtres invàlids.
  void _handleAltitudeChanged() {
    if (!mounted) return;
    setState(() {});
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

  // Aquest getter detecta quan l'usuari ha omplert només una part del
  // filtre meteorològic. La UI mostra un avís perquè entengui per què
  // l'aplicació del filtre no tindrà efecte sense la part que falta.
  bool get _hasPartialWeatherFilter {
    final hasDate = _selectedWeatherDate != null;
    final hasConditions = _selectedWeatherConditions.isNotEmpty;
    return hasDate != hasConditions;
  }

  // Aquest mètode comprova si el rang d'altura introduït és possible.
  // Només marca error quan els dos camps tenen valor i la mínima supera la màxima.
  bool get _hasInvalidAltitudeRange {
    final minAltitude = _parseAltitude(_minAltitudeController.text);
    final maxAltitude = _parseAltitude(_maxAltitudeController.text);

    if (minAltitude == null || maxAltitude == null) {
      return false;
    }

    return minAltitude > maxAltitude;
  }

  // Aquest mètode reinicia tots els filtres visibles del panell.
  // Primer tanca el panell i després executa la neteja per evitar reconstruir el mapa sota el modal.
  Future<void> _handleClear() async {
    _minAltitudeController.clear();
    _maxAltitudeController.clear();

    setState(() {
      _selectedRegionId = null;
      _selectedStatusFilter = PeakStatusFilter.none;
      _selectedWeatherDate = null;
      _selectedWeatherConditions = <WeatherConditionType>{};
    });

    final onClear = widget.onClear;

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onClear();
    });
  }

  // Aquest mètode recull els valors seleccionats i els envia a la pantalla principal.
  // Si el rang d'altura no és possible, no permet aplicar el filtre.
  void _handleApply() {
    if (_hasInvalidAltitudeRange) {
      return;
    }

    final minAltitude = _parseAltitude(_minAltitudeController.text);
    final maxAltitude = _parseAltitude(_maxAltitudeController.text);
    final selectedRegionId = _selectedRegionId;
    final selectedStatusFilter = _selectedStatusFilter;
    // El filtre meteorològic només s'envia quan totes dues parts estan
    // informades; si l'usuari només ha triat data o només condicions,
    // s'ignora silenciosament perquè el backend rebutjaria un enviament
    // parcial amb 400 i la pantalla quedaria en estat d'error.
    final hasWeatherFilter = _selectedWeatherDate != null &&
        _selectedWeatherConditions.isNotEmpty;
    final weatherDate = hasWeatherFilter ? _selectedWeatherDate : null;
    final weatherConditions = hasWeatherFilter
        ? Set<WeatherConditionType>.from(_selectedWeatherConditions)
        : <WeatherConditionType>{};
    final onApply = widget.onApply;

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onApply(
        regionId: selectedRegionId,
        minAltitude: minAltitude,
        maxAltitude: maxAltitude,
        statusFilter: selectedStatusFilter,
        weatherDate: weatherDate,
        weatherConditions: weatherConditions,
      );
    });
  }

  // Aquest mètode allibera els controladors dels camps quan es tanca el panell.
  // Evita mantenir recursos actius que ja no són necessaris.
  @override
  void dispose() {
    _minAltitudeController.removeListener(_handleAltitudeChanged);
    _maxAltitudeController.removeListener(_handleAltitudeChanged);
    _minAltitudeController.dispose();
    _maxAltitudeController.dispose();
    super.dispose();
  }

  // Aquest mètode construeix el contingut visual del panell de filtres.
  // Agrupa els filtres per comarca, altitud i estat personal en un únic formulari.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInvalidAltitudeRange = _hasInvalidAltitudeRange;

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
                    PeaksWeatherFilterSection(
                      selectedDate: _selectedWeatherDate,
                      selectedConditions: _selectedWeatherConditions,
                      onDateChanged: (value) {
                        setState(() {
                          _selectedWeatherDate = value;
                        });
                      },
                      onConditionToggled: (condition) {
                        setState(() {
                          if (_selectedWeatherConditions.contains(condition)) {
                            _selectedWeatherConditions.remove(condition);
                          } else {
                            _selectedWeatherConditions.add(condition);
                          }
                        });
                      },
                    ),
                    if (_hasPartialWeatherFilter) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedWeatherDate == null
                            ? 'Tria també un dia perquè s\'apliqui el filtre meteorològic.'
                            : 'Tria també almenys una condició meteorològica.',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
    );
  }
}