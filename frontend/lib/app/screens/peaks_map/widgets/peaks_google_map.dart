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
    this.height = 380,
    this.showSummary = true,
    this.isInteractive = true,
  });

  // Aquest bloc rep els cims que s’han de representar i el cim seleccionat.
  // També rep l’acció que s’executa quan l’usuari toca un marcador del mapa.
  final List<Peak> peaks;
  final Peak? selectedPeak;
  final ValueChanged<Peak> onPeakTap;
  final double height;
  final bool showSummary;
  final bool isInteractive;

  @override
  State<PeaksGoogleMap> createState() => _PeaksGoogleMapState();
}

// Aquesta classe manté el controller intern del mapa.
// També centra la càmera quan es crea el mapa o quan l’usuari selecciona un cim.
class _PeaksGoogleMapState extends State<PeaksGoogleMap> {
  GoogleMapController? _mapController;

  static const LatLng _cataloniaCenter = LatLng(41.7830, 1.8260);

  // Retorna només els cims que tenen coordenades disponibles.
  // Això evita intentar crear marcadors amb dades incompletes.
  List<Peak> get _visiblePeaks =>
      widget.peaks.where((peak) => peak.hasMapPosition).toList();

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

    if (!_sameVisiblePeaks(oldWidget.peaks, widget.peaks)) {
      _fitVisiblePeaks();
    }
  }

  // Compara els cims visibles abans i després d’una actualització.
  // Això permet reajustar la càmera quan canvien la cerca o els filtres.
  bool _sameVisiblePeaks(List<Peak> previousPeaks, List<Peak> currentPeaks) {
    final previousIds = previousPeaks
        .where((peak) => peak.hasMapPosition)
        .map((peak) => peak.id)
        .toList();

    final currentIds = currentPeaks
        .where((peak) => peak.hasMapPosition)
        .map((peak) => peak.id)
        .toList();

    return listEquals(previousIds, currentIds);
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

  // Converteix els cims visibles en marcadors de Google Maps.
  // Cada marcador permet seleccionar el cim i mostrar-ne la informació resumida.
  Set<Marker> _buildMarkers() {
    return _visiblePeaks.map((peak) {
      final isSelected = widget.selectedPeak?.id == peak.id;

      return Marker(
        markerId: MarkerId('peak_${peak.id}'),
        position: LatLng(peak.latitude!, peak.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: peak.name,
          snippet: '${peak.altitude} m',
        ),
        onTap: () => widget.onPeakTap(peak),
      );
    }).toSet();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Construeix el mapa real amb Google Maps.
  // Manté el mateix flux que el placeholder anterior: marcadors, selecció i resum inferior.
  @override
  Widget build(BuildContext context) {
    final visiblePeaks = _visiblePeaks;

    if (visiblePeaks.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCameraPosition(),
              markers: _buildMarkers(),
              mapType: MapType.terrain,
              onMapCreated: _onMapCreated,
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
            if (widget.showSummary)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: _MapSummaryBadge(
                  totalPeaks: visiblePeaks.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Aquest element mostra quants cims s’estan representant al mapa.
// Ajuda l’usuari a entendre el resultat de la cerca i dels filtres aplicats.
class _MapSummaryBadge extends StatelessWidget {
  const _MapSummaryBadge({
    required this.totalPeaks,
  });

  // Nombre total de cims visibles amb la cerca i els filtres actuals.
  final int totalPeaks;

  // Mostra una etiqueta informativa sobre el volum de cims representats.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$totalPeaks cims visibles al mapa',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF17212B),
        ),
      ),
    );
  }
}
