import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_marker_factory.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
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

  static const LatLng _cataloniaCenter = LatLng(41.7830, 1.8260);

  final PeaksMapMarkerFactory _markerFactory = PeaksMapMarkerFactory();

  BitmapDescriptor? _peakMarker;

  // Retorna només els cims que tenen coordenades disponibles.
  // Això evita intentar crear marcadors amb dades incompletes.
  List<Peak> get _visiblePeaks =>
      widget.peaks.where((peak) => peak.hasMapPosition).toList();

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  @override
  void didUpdateWidget(covariant PeaksGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.statusFilter != widget.statusFilter) {
      _loadMarker();
    }

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

  // Carrega el marcador circular corresponent al filtre actiu.
  // El marcador es reutilitza des de la factoria per evitar generar-lo repetidament.
  Future<void> _loadMarker() async {
    final currentFilter = widget.statusFilter;
    final marker = await _markerFactory.markerForFilter(currentFilter);

    if (!mounted || currentFilter != widget.statusFilter) {
      return;
    }

    setState(() {
      _peakMarker = marker;
    });
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

  // Converteix els cims visibles en marcadors circulars de Google Maps.
  // El color del marcador depèn del filtre d’estat aplicat al mapa.
  Set<Marker> _buildMarkers() {
    final markerIcon = _peakMarker ??
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );

    return _visiblePeaks.map((peak) {
      return Marker(
        markerId: MarkerId('peak_${peak.id}'),
        position: LatLng(peak.latitude!, peak.longitude!),
        icon: markerIcon,
        anchor: const Offset(0.5, 0.5),
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
  // Manté els marcadors, el resum inferior i la targeta flotant del cim seleccionat.
  @override
  Widget build(BuildContext context) {
    final visiblePeaks = _visiblePeaks;

    if (visiblePeaks.isEmpty) {
      return const SizedBox.shrink();
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
              child: _SelectedPeakMapCard(
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
                child: _MapSummaryBadge(
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

// Aquesta targeta mostra el cim seleccionat dins del mateix mapa.
// Substitueix la targeta inferior externa i manté l’accés directe al detall.
class _SelectedPeakMapCard extends StatelessWidget {
  const _SelectedPeakMapCard({
    required this.peak,
    required this.onDetailTap,
  });

  // Aquest bloc rep el cim seleccionat i l’acció per obrir-ne el detall.
  final Peak peak;
  final VoidCallback onDetailTap;

  // Construeix una targeta compacta amb la informació principal i el botó d’acció.
  @override
  Widget build(BuildContext context) {
    final regionsText = peak.formattedRegions.isEmpty
        ? 'Sense comarca informada'
        : peak.formattedRegions;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            peak.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17212B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${peak.altitude} m · $regionsText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5B6573),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 118,
              child: PrimaryGradientButton(
                label: 'Detall',
                icon: Icons.open_in_new_rounded,
                height: 38,
                fontSize: 15,
                iconSize: 16,
                onPressed: onDetailTap,
              ),
            ),
          ),
        ],
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
        '$totalPeaks cims',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF17212B),
        ),
      ),
    );
  }
}