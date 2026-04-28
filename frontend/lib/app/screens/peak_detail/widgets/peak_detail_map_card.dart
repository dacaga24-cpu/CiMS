import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_map/widgets/peaks_map_marker_factory.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Aquest widget mostra la ubicació del cim dins del detall.
// Inclou una vista de mapa no interactiva i un accés directe a la pantalla de mapa.
class PeakDetailMapCard extends StatefulWidget {
  const PeakDetailMapCard({
    super.key,
    required this.peak,
    required this.onTap,
  });

  final Peak peak;
  final VoidCallback onTap;

  @override
  State<PeakDetailMapCard> createState() => _PeakDetailMapCardState();
}

// Aquesta classe gestiona la càrrega del marcador del mapa.
// Manté separat el procés de preparació visual del marcador respecte a la construcció de la targeta.
class _PeakDetailMapCardState extends State<PeakDetailMapCard> {
  final PeaksMapMarkerFactory _markerFactory = PeaksMapMarkerFactory();

  BitmapDescriptor? _markerIcon;

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  // Carrega el marcador circular genèric del mapa.
  // Es fa servir el mateix estil visual que a la pantalla principal de mapa.
  Future<void> _loadMarker() async {
    final marker = await _markerFactory.markerForFilter(PeakStatusFilter.none);

    if (!mounted) {
      return;
    }

    setState(() {
      _markerIcon = marker;
    });
  }

  // Aquest mètode construeix la targeta del mapa dins del detall del cim.
  // Si el cim té coordenades, mostra una previsualització; si no en té, mostra un estat alternatiu.
  @override
  Widget build(BuildContext context) {
    final peak = widget.peak;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (peak.hasMapPosition)
              GestureDetector(
                onTap: widget.onTap,
                child: _PeakStaticMapPreview(
                  peak: peak,
                  markerIcon: _markerIcon,
                ),
              )
            else
              const _PeakMapUnavailablePreview(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Aquesta vista mostra un mapa real però sense interacció.
// Serveix com a previsualització visual de la ubicació del cim.
class _PeakStaticMapPreview extends StatelessWidget {
  const _PeakStaticMapPreview({
    required this.peak,
    required this.markerIcon,
  });

  final Peak peak;
  final BitmapDescriptor? markerIcon;

  // Aquest mètode prepara la posició i el marcador del cim dins del mapa.
  // El mapa queda bloquejat perquè funcioni només com a vista prèvia i no com a pantalla interactiva.
  @override
  Widget build(BuildContext context) {
    final position = LatLng(
      peak.latitude!,
      peak.longitude!,
    );

    final marker = Marker(
      markerId: MarkerId('peak_${peak.id}'),
      position: position,
      icon: markerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
      anchor: const Offset(0.5, 0.5),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 170,
        child: AbsorbPointer(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: position,
              zoom: 11,
            ),
            markers: {marker},
            mapType: MapType.terrain,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: false,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: false,
          ),
        ),
      ),
    );
  }
}

// Aquest estat es mostra quan el cim encara no disposa de coordenades.
// Manté una alternativa visual clara sense trencar el disseny de la targeta.
class _PeakMapUnavailablePreview extends StatelessWidget {
  const _PeakMapUnavailablePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8EEF5),
            Color(0xFFD9E2EC),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 44,
              color: Color(0xFF5D6C80),
            ),
            SizedBox(height: 8),
            Text(
              'Vista de mapa no disponible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
