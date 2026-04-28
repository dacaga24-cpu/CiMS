import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Aquesta classe crea els marcadors circulars del mapa.
// Centralitza els colors i evita que el widget del mapa hagi de generar
// les icones directament.
class PeaksMapMarkerFactory {
  // Colors utilitzats per diferenciar visualment els marcadors segons l’estat del cim.
  static const Color primaryColor = Color(0xFF0E63F4);
  static const Color completedColor = Color(0xFF18B56A);
  static const Color targetColor = Color(0xFFF97316);
  static const Color favoriteColor = Color(0xFFE84A4A);

  // Guarda els marcadors ja generats per reutilitzar-los en futures càrregues del mapa.
  final Map<PeakStatusFilter, BitmapDescriptor> _cache = {};

  // Retorna el marcador corresponent al filtre actiu.
  // Si ja s'ha generat abans, el reutilitza per evitar treball innecessari.
  Future<BitmapDescriptor> markerForFilter(PeakStatusFilter filter) async {
    final cachedMarker = _cache[filter];

    if (cachedMarker != null) {
      return cachedMarker;
    }

    final marker = await _buildCircleMarker(
      fillColor: _colorForFilter(filter),
    );

    _cache[filter] = marker;
    return marker;
  }

  // Decideix el color del marcador segons el filtre d'estat aplicat.
  // Quan no hi ha cap filtre específic, es fa servir el blau principal de l'app.
  Color _colorForFilter(PeakStatusFilter filter) {
    switch (filter) {
      case PeakStatusFilter.completed:
        return completedColor;
      case PeakStatusFilter.target:
        return targetColor;
      case PeakStatusFilter.favorite:
        return favoriteColor;
      case PeakStatusFilter.none:
      case PeakStatusFilter.pending:
        return primaryColor;
    }
  }

  // Genera una icona circular amb fons de color i traç exterior blanc.
  // El resultat es converteix en un BitmapDescriptor que Google Maps pot mostrar.
  Future<BitmapDescriptor> _buildCircleMarker({
    required Color fillColor,
  }) async {
    const double size = 24;
    const double borderWidth = 4;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = ui.Offset(size / 2, size / 2);

    final borderPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.fill;

    final fillPaint = ui.Paint()
      ..color = fillColor
      ..style = ui.PaintingStyle.fill;

    canvas.drawCircle(center, size / 2, borderPaint);
    canvas.drawCircle(center, (size / 2) - borderWidth, fillPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.toInt(),
      size.toInt(),
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }

    return BitmapDescriptor.bytes(
      Uint8List.view(byteData.buffer),
    );
  }
}
