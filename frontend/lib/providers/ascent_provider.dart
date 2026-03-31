// ascent_provider.dart
// Responsabilidad: Gestión del estado de las ascensiones.
// Extiende ChangeNotifier para notificar a los widgets consumidores.
// Delega las llamadas HTTP al AscentService.
// NO contiene lógica HTTP directa.

import 'package:flutter/material.dart';
// import '../services/ascent_service.dart';
// import '../models/ascent.dart';

class AscentProvider extends ChangeNotifier {
  // Estado
  // List<Ascent> _userAscents = [];
  // List<Ascent> _peakAscents = [];
  // bool _isLoading = false;
  // String? _error;

  // Registra una nueva ascensión: llama a AscentService.create
  Future<void> createAscent({
    required int peakId,
    required String ascentDate,
    String? notes,
  }) async {}

  // Actualiza una ascensión: llama a AscentService.update
  Future<void> updateAscent({
    required int id,
    required String ascentDate,
    String? notes,
  }) async {}

  // Elimina una ascensión: llama a AscentService.delete
  Future<void> deleteAscent(int id) async {}

  // Carga las ascensiones de un usuario: llama a AscentService.getByUser
  Future<void> loadUserAscents(int userId) async {}

  // Carga las ascensiones a un cim: llama a AscentService.getByPeak
  Future<void> loadPeakAscents(int peakId) async {}
}
