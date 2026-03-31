// peak_provider.dart
// Responsabilidad: Gestión del estado de los cims.
// Extiende ChangeNotifier para notificar a los widgets consumidores.
// Delega las llamadas HTTP al PeakService.
// NO contiene lógica HTTP directa.

import 'package:flutter/material.dart';
// import '../services/peak_service.dart';
// import '../models/peak.dart';

class PeakProvider extends ChangeNotifier {
  // Estado
  // List<Peak> _peaks = [];
  // Peak? _selectedPeak;
  // bool _isLoading = false;
  // String? _error;

  // Carga todos los cims: llama a PeakService.getAll
  Future<void> loadPeaks() async {}

  // Carga un cim por ID: llama a PeakService.getById
  Future<void> loadPeakById(int id) async {}

  // Carga cims de una comarca: llama a PeakService.getByRegion
  Future<void> loadPeaksByRegion(int regionId) async {}

  // Filtra cims por altitud: llama a PeakService.getByAltitude
  Future<void> loadPeaksByAltitude(int min, int max) async {}

  // Busca cims por nombre: llama a PeakService.search
  Future<void> searchPeaks(String query) async {}
}
