import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_marker_factory.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_selected_peak_card.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_summary_badge.dart';
import 'package:cims/core/entity/peak.dart';
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

  // Retorna només els cims que tenen coordenades disponibles.
  // Això evita intentar crear marcadors amb dades incompletes.
  List<Peak> get _visiblePeaks =>
      widget.peaks.where((peak) => peak.hasMapPosition).toList();

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // Detecta si ha canviat el cim seleccionat des de fora del widget.
  // Quan això passa, centra la càmera perquè el mapa mostri clarament el nou cim.
  @override
  void didUpdateWidget(covariant PeaksGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousSelectedId = oldWidget.selectedPeak?.id;
    final currentSelectedId = widget.selectedPeak?.id;

    if (previousSelectedId != currentSelectedId &&
        widget.selectedPeak != null) {
      _centerSelectedPeak();
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

    if (!mounted) {
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
    _mapController = controller;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitVisiblePeaks();
    });
  }

  // Centra la càmera sobre el cim seleccionat.
  // Això fa que tocar un marcador tingui una resposta visual clara.
  Future<void> _centerSelectedPeak() async {
    final controller = _mapController;
    final peak = widget.selectedPeak;

    if (controller == null || peak == null || !peak.hasMapPosition) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(peak.latitude!, peak.longitude!),
        12,
      ),
    );
  }

  // Ajusta la càmera perquè els cims carregats siguin visibles al mapa.
  // Si només hi ha un cim, centra directament sobre aquell punt.
  Future<void> _fitVisiblePeaks() async {
    final controller = _mapController;
    final peaks = _visiblePeaks;

    if (controller == null || peaks.isEmpty) {
      return;
    }

    if (peaks.length == 1) {
      final peak = peaks.first;

      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(peak.latitude!, peak.longitude!),
          11,
        ),
      );
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
      // Si el mapa encara no està preparat per ajustar límits,
      // es manté la posició inicial sense trencar la pantalla.
    }
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
  // Això permet que un mateix cim pugui aparèixer amb colors diferents segons el filtre,
  // sense que Google Maps Web intenti actualitzar un marcador eliminat.
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
    _mapController?.dispose();
    super.dispose();
  }

  // Construeix el mapa real amb Google Maps.
  // Manté els marcadors, el resum inferior i la targeta flotant del cim seleccionat.
  @override
  Widget build(BuildContext context) {
    final visiblePeaks = _visiblePeaks;

    if (visiblePeaks.isEmpty) {
      return const SizedBox.shrink();
    }

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
          if (widget.selectedPeak != null)
            Positioned(
              left: 18,
              right: 18,
              top: 18,
              child: PeaksMapSelectedPeakCard(
                peak: widget.selectedPeak!,
                onDetailTap: widget.onSelectedPeakDetailTap,
              ),
            ),
          if (widget.showSummary)
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
