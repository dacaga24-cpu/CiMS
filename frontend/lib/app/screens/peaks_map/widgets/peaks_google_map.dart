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
import 'package:pointer_interceptor/pointer_interceptor.dart';

// Aquest widget encapsula el mapa de Google Maps.
// Mostra els cims amb coordenades com a marcadors interactius.
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

  // Aquestes dades defineixen els cims visibles, el cim seleccionat i les accions del mapa.
  final List<Peak> peaks;
  final Peak? selectedPeak;
  final ValueChanged<Peak> onPeakTap;
  final VoidCallback onSelectedPeakDetailTap;
  final VoidCallback onMapTap;

  // Aquesta funció permet obtenir l’estat personal d’un cim.
  // S’utilitza per mostrar accions ràpides a la targeta del cim seleccionat.
  final PeakStatus? Function(int peakId)? statusForPeak;

  // Aquestes accions permeten modificar objectiu i preferit des del mapa.
  final VoidCallback? onSelectedPeakTargetTap;
  final VoidCallback? onSelectedPeakFavoriteTap;

  final double? height;
  final bool showSummary;
  final bool isInteractive;
  final PeakStatusFilter statusFilter;

  @override
  State<PeaksGoogleMap> createState() => _PeaksGoogleMapState();
}

// Aquest estat controla el mapa i la seva càmera.
// També prepara els marcadors i centra la vista quan canvien els cims visibles.
class _PeaksGoogleMapState extends State<PeaksGoogleMap> {
  GoogleMapController? _mapController;

  // Aquest punt s’utilitza com a posició inicial quan no hi ha cims visibles.
  static const LatLng _cataloniaCenter = LatLng(41.7830, 1.8260);

  // Aquests límits defineixen una àrea raonable per als cims de Catalunya.
  // Eviten que coordenades corruptes deformin l’enquadrament del mapa.
  static const double _catalunyaMinLat = 40.0;
  static const double _catalunyaMaxLat = 43.0;
  static const double _catalunyaMinLng = 0.0;
  static const double _catalunyaMaxLng = 3.5;

  final PeaksMapMarkerFactory _markerFactory = PeaksMapMarkerFactory();

  // Aquest mapa guarda una icona de marcador per cada filtre d’estat.
  final Map<PeakStatusFilter, BitmapDescriptor> _markersByFilter = {};

  bool _areMarkersReady = false;
  bool _disposed = false;

  // Aquest comptador evita aplicar ajustos de càmera antics.
  // Només l’última petició d’enquadrament pot modificar el mapa.
  int _fitRequestId = 0;

  // Aquest getter retorna només els cims amb coordenades vàlides dins de Catalunya.
  List<Peak> get _visiblePeaks =>
      widget.peaks.where(_isWithinCatalunya).toList();

  bool _isWithinCatalunya(Peak peak) {
    if (!peak.hasMapPosition) return false;
    final lat = peak.latitude!;
    final lng = peak.longitude!;
    return lat >= _catalunyaMinLat &&
        lat <= _catalunyaMaxLat &&
        lng >= _catalunyaMinLng &&
        lng <= _catalunyaMaxLng;
  }

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // Aquest mètode detecta canvis externs en el cim seleccionat o en els cims visibles.
  // Si cal, centra la càmera o reajusta l’enquadrament del mapa.
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

  // Aquest mètode carrega les icones dels marcadors una sola vegada.
  // Això permet canviar el color segons el filtre sense recrear recursos constantment.
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

  // Aquest mètode guarda el controller quan el mapa ja està creat.
  // Després ajusta la càmera als cims visibles.
  void _onMapCreated(GoogleMapController controller) {
    if (_disposed) return;
    _mapController = controller;
    _fitVisiblePeaks();
  }

  // Aquest mètode centra la càmera sobre el cim seleccionat.
  // Dona una resposta visual clara quan l’usuari toca un marcador.
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
      // Si el mapa ja no està disponible, es manté la vista actual.
    }
  }

  // Aquest mètode ajusta la càmera perquè els cims visibles quedin enquadrats.
  // Si els cims estan molt junts, força un zoom útil per veure millor els marcadors.
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
          // Si l’animació falla, no es bloqueja la pantalla.
        }
        return;
      }

      final bounds = _boundsForPeaks(peaks);

      const compactSpanThreshold = 0.05;
      final latSpan =
          (bounds.northeast.latitude - bounds.southwest.latitude).abs();
      final lngSpan =
          (bounds.northeast.longitude - bounds.southwest.longitude).abs();
      if (latSpan < compactSpanThreshold && lngSpan < compactSpanThreshold) {
        final centerLat =
            (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final centerLng =
            (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
        try {
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(centerLat, centerLng),
              12,
            ),
          );
        } catch (_) {
          // Si l’animació falla, es conserva l’estat actual del mapa.
        }
        return;
      }

      final padding = peaks.length > 10 ? 40.0 : 24.0;

      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, padding),
        );
      } catch (_) {
        // Si no es pot ajustar la càmera, el mapa continua funcionant.
      }
    });
  }

  // Aquest mètode calcula els límits geogràfics dels cims visibles.
  // Google Maps els utilitza per enquadrar tots els marcadors.
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

  // Aquest mètode defineix la posició inicial del mapa.
  // Prioritza el cim seleccionat i, si no existeix, calcula un centre aproximat.
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

  // Aquest mètode converteix els cims visibles en marcadors de Google Maps.
  // La icona depèn del filtre actiu per mantenir coherència visual.
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

  // Aquest mètode allibera el controller intern de Google Maps.
  @override
  void dispose() {
    _disposed = true;
    try {
      _mapController?.dispose();
    } catch (_) {
      // El controller ja no està disponible; no cal cap acció addicional.
    }
    super.dispose();
  }

  // Aquest mètode construeix el mapa amb marcadors, resum i targeta flotant.
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
              // Aquest interceptor evita que els clics sobre la targeta arribin al mapa.
              // És necessari en web perquè Google Maps es renderitza com a platform view.
              child: PointerInterceptor(
                child: PeaksMapSelectedPeakCard(
                  peak: selectedPeak,
                  status: widget.statusForPeak?.call(selectedPeak.id),
                  onDetailTap: widget.onSelectedPeakDetailTap,
                  onTargetTap: widget.onSelectedPeakTargetTap,
                  onFavoriteTap: widget.onSelectedPeakFavoriteTap,
                ),
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
