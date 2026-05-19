import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_marker_factory.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_selected_peak_card.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_summary_badge.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Aquest widget encapsula el component real de Google Maps.
// Rep una llista de cims amb coordenades i els transforma en marcadors interactius.
class PeaksGoogleMap extends StatefulWidget {
  const PeaksGoogleMap({
    super.key,
    required this.peaks,
    required this.selectedPeak,
    required this.onPeakTap,
    required this.onSelectedPeakDetailTap,
    required this.onMapTap,
    this.statusForPeak,
    this.onSelectedPeakTargetTap,
    this.onSelectedPeakFavoriteTap,
    this.height,
    this.showSummary = true,
    this.isInteractive = true,
    this.statusFilter = PeakStatusFilter.none,
  });

  // Aquest bloc rep els cims que s’han de representar i el cim seleccionat.
  // També rep les accions que s’executen quan l’usuari toca un marcador, el mapa o obre el detall.
  final List<Peak> peaks;
  final Peak? selectedPeak;
  final ValueChanged<Peak> onPeakTap;
  final VoidCallback onSelectedPeakDetailTap;
  final VoidCallback onMapTap;

  // Aquesta funció permet obtenir l’estat personal del cim seleccionat.
  // S’utilitza per mostrar completat, objectiu i preferit a la targeta ràpida del mapa.
  final PeakStatus? Function(int peakId)? statusForPeak;

  // Aquestes accions permeten modificar objectiu i preferit des del detall ràpid.
  // El completat no es modifica manualment perquè deriva de les ascensions.
  final VoidCallback? onSelectedPeakTargetTap;
  final VoidCallback? onSelectedPeakFavoriteTap;

  final double? height;
  final bool showSummary;
  final bool isInteractive;
  final PeakStatusFilter statusFilter;

  @override
  State<PeaksGoogleMap> createState() => _PeaksGoogleMapState();
}

// Aquesta classe manté el controller intern del mapa.
// També centra la càmera quan es crea el mapa o quan l’usuari selecciona un cim.
class _PeaksGoogleMapState extends State<PeaksGoogleMap> {
  GoogleMapController? _mapController;

  // Punt central de Catalunya utilitzat com a posició inicial del mapa.
  // Serveix quan encara no hi ha cap cim seleccionat o visible.
  static const LatLng _cataloniaCenter = LatLng(41.7830, 1.8260);

  final PeaksMapMarkerFactory _markerFactory = PeaksMapMarkerFactory();

  // Aquest mapa guarda una icona preparada per a cada filtre d’estat.
  // Això evita regenerar o actualitzar icones sobre marcadors que Google Maps Web ja ha eliminat.
  final Map<PeakStatusFilter, BitmapDescriptor> _markersByFilter = {};

  bool _areMarkersReady = false;

  // Marca que el state ja s'ha disposat i evita que callbacks pendents
  // intentin actuar sobre un controller que ja s'ha alliberat.
  bool _disposed = false;

  // Identifica la petició de fit més recent. Quan l'usuari canvia de filtre
  // o de cerca diverses vegades seguides més ràpid del que dura una animació
  // de càmera, només la última petició s'ha d'aplicar.
  int _fitRequestId = 0;

  // Retorna només els cims que tenen coordenades disponibles.
  // Això evita intentar crear marcadors amb dades incompletes.
  List<Peak> get _visiblePeaks =>
      widget.peaks.where((peak) => peak.hasMapPosition).toList();

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // Detecta si ha canviat el cim seleccionat o la llista de cims des de fora
  // del widget. Quan canvia el seleccionat, centra la càmera sobre el cim.
  @override
  void didUpdateWidget(covariant PeaksGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousSelectedId = oldWidget.selectedPeak?.id;
    final currentSelectedId = widget.selectedPeak?.id;

    if (previousSelectedId != currentSelectedId &&
        widget.selectedPeak != null) {
      _centerSelectedPeak();
      return;
    }

    final currentVisible = _visiblePeaks;
    if (currentVisible.isEmpty) {
      return;
    }

    final previousVisibleIdsHash = Object.hashAll(
      oldWidget.peaks
          .where((peak) => peak.hasMapPosition)
          .map((peak) => peak.id),
    );
    final currentVisibleIdsHash =
        Object.hashAll(currentVisible.map((peak) => peak.id));

    if (previousVisibleIdsHash != currentVisibleIdsHash) {
      _fitVisiblePeaks();
    }
  }

  // Carrega totes les icones de marcador una sola vegada.
  // D’aquesta manera el color pot canviar segons el filtre actiu sense modificar
  // directament la icona d’un marcador ja existent al mapa web.
  Future<void> _loadMarkers() async {
    final markerEntries = await Future.wait(
      PeakStatusFilter.values.map((filter) async {
        final marker = await _markerFactory.markerForFilter(filter);
        return MapEntry(filter, marker);
      }),
    );

    if (!mounted || _disposed) {
      return;
    }

    setState(() {
      _markersByFilter
        ..clear()
        ..addEntries(markerEntries);
      _areMarkersReady = true;
    });
  }

  // Guarda el controller del mapa quan Google Maps ja està carregat.
  // Després ajusta la càmera perquè els cims visibles quedin dins de la vista.
  void _onMapCreated(GoogleMapController controller) {
    if (_disposed) return;
    _mapController = controller;
    _fitVisiblePeaks();
  }

  // Centra la càmera sobre el cim seleccionat.
  // Això fa que tocar un marcador tingui una resposta visual clara.
  Future<void> _centerSelectedPeak() async {
    if (_disposed) return;

    final controller = _mapController;
    final peak = widget.selectedPeak;

    if (controller == null || peak == null || !peak.hasMapPosition) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(peak.latitude!, peak.longitude!),
          12,
        ),
      );
    } catch (_) {
      // Si el controller s'ha alliberat o l'animació falla, no es propaga
      // l'error perquè la pantalla principal pugui continuar funcionant.
    }
  }

  // Ajusta la càmera perquè els cims carregats siguin visibles al mapa.
  // Si només hi ha un cim, centra directament sobre aquell punt.
  void _fitVisiblePeaks() {
    if (_disposed) return;
    final requestId = ++_fitRequestId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _disposed || requestId != _fitRequestId) return;

      final controller = _mapController;
      final peaks = _visiblePeaks;

      if (controller == null || peaks.isEmpty) return;

      if (peaks.length == 1) {
        final peak = peaks.first;

        try {
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(peak.latitude!, peak.longitude!),
              11,
            ),
          );
        } catch (_) {
          // Si el controller ja no és accessible o l'animació falla,
          // es manté la vista actual sense propagar l'error.
        }
        return;
      }

      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsForPeaks(peaks),
            48,
          ),
        );
      } catch (_) {
        // Mateix raonament que al cas d'un sol cim.
      }
    });
  }

  // Calcula els límits geogràfics dels cims visibles.
  // Google Maps els utilitza per enquadrar automàticament tots els marcadors.
  LatLngBounds _boundsForPeaks(List<Peak> peaks) {
    double south = peaks.first.latitude!;
    double north = peaks.first.latitude!;
    double west = peaks.first.longitude!;
    double east = peaks.first.longitude!;

    for (final peak in peaks) {
      final latitude = peak.latitude!;
      final longitude = peak.longitude!;

      if (latitude < south) south = latitude;
      if (latitude > north) north = latitude;
      if (longitude < west) west = longitude;
      if (longitude > east) east = longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  // Defineix la posició inicial del mapa abans que es pugui ajustar la càmera.
  // Prioritza el cim seleccionat i, si no n’hi ha, calcula un centre aproximat.
  CameraPosition _initialCameraPosition() {
    final selectedPeak = widget.selectedPeak;

    if (selectedPeak != null && selectedPeak.hasMapPosition) {
      return CameraPosition(
        target: LatLng(selectedPeak.latitude!, selectedPeak.longitude!),
        zoom: 12,
      );
    }

    final peaks = _visiblePeaks;
    if (peaks.isEmpty) {
      return const CameraPosition(
        target: _cataloniaCenter,
        zoom: 7,
      );
    }

    final latitudeSum = peaks.fold<double>(
      0,
      (sum, peak) => sum + peak.latitude!,
    );
    final longitudeSum = peaks.fold<double>(
      0,
      (sum, peak) => sum + peak.longitude!,
    );

    return CameraPosition(
      target: LatLng(
        latitudeSum / peaks.length,
        longitudeSum / peaks.length,
      ),
      zoom: 7.5,
    );
  }

  // Converteix els cims visibles en marcadors circulars de Google Maps.
  // El color depèn del filtre actiu i l'identificador també inclou aquest filtre.
  Set<Marker> _buildMarkers() {
    final markerIcon = _markersByFilter[widget.statusFilter] ??
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );

    return _visiblePeaks.map((peak) {
      return Marker(
        markerId: MarkerId('peak_${peak.id}_${widget.statusFilter.name}'),
        position: LatLng(peak.latitude!, peak.longitude!),
        icon: markerIcon,
        anchor: const Offset(0.5, 0.5),
        onTap: () => widget.onPeakTap(peak),
      );
    }).toSet();
  }

  // Allibera el controller intern de Google Maps quan el widget es destrueix.
  // Això evita mantenir recursos del mapa actius fora de la pantalla.
  @override
  void dispose() {
    _disposed = true;
    try {
      _mapController?.dispose();
    } catch (_) {
      // El controller ja no està accessible; no hi ha res més a netejar
      // per la nostra banda.
    }
    super.dispose();
  }

  // Construeix el mapa real amb Google Maps.
  // Manté els marcadors, el resum inferior i la targeta flotant del cim seleccionat.
  @override
  Widget build(BuildContext context) {
    final visiblePeaks = _visiblePeaks;
    final selectedPeak = widget.selectedPeak;

    if (!_areMarkersReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final mapContent = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition(),
            markers: _buildMarkers(),
            mapType: MapType.terrain,
            onMapCreated: _onMapCreated,
            onTap: (_) => widget.onMapTap(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: widget.isInteractive,
            rotateGesturesEnabled: widget.isInteractive,
            scrollGesturesEnabled: widget.isInteractive,
            tiltGesturesEnabled: widget.isInteractive,
            zoomGesturesEnabled: widget.isInteractive,
            gestureRecognizers: widget.isInteractive
                ? <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  }
                : const <Factory<OneSequenceGestureRecognizer>>{},
          ),
          if (selectedPeak != null)
            Positioned(
              left: 18,
              right: 18,
              top: 18,
              child: PeaksMapSelectedPeakCard(
                peak: selectedPeak,
                status: widget.statusForPeak?.call(selectedPeak.id),
                onDetailTap: widget.onSelectedPeakDetailTap,
                onTargetTap: widget.onSelectedPeakTargetTap,
                onFavoriteTap: widget.onSelectedPeakFavoriteTap,
              ),
            ),
          if (widget.showSummary && visiblePeaks.isNotEmpty)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Center(
                child: PeaksMapSummaryBadge(
                  totalPeaks: visiblePeaks.length,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.height == null) {
      return SizedBox.expand(
        child: mapContent,
      );
    }

    return SizedBox(
      height: widget.height,
      child: mapContent,
    );
  }
}