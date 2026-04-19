import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/usecase/get_peaks_usecase.dart';
import 'package:flutter/material.dart';

// Aquest controlador gestiona l’estat local de la pantalla del catàleg.
// Carrega els cims de mostra, manté l’opció visual seleccionada
// i prepara l’estructura perquè més endavant s’hi pugui connectar la lògica real.
class PeaksCatalogController extends ChangeNotifier {
  PeaksCatalogController({
    GetPeaksUseCase? getPeaksUseCase,
  }) : _getPeaksUseCase = getPeaksUseCase ?? const GetPeaksUseCase();

  final GetPeaksUseCase _getPeaksUseCase;
  final searchController = TextEditingController();

  bool isLoading = false;
  List<Peak> peaks = const [];

  bool _disposed = false;

  // Aquest mètode carrega les dades inicials del catàleg.
  // Es crida en iniciar la pantalla per separar l’obtenció de dades del build visual.
  Future<void> initialize() async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      peaks = await _getPeaksUseCase.execute();
    } finally {
      isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode es reserva per al futur comportament de la cerca.
  // Ara només força el refresc visual si es vol reaccionar a l’entrada de text.
  void onSearchChanged(String value) {
    notifyListeners();
  }

  // Aquest mètode tanca correctament els recursos del controller quan la pantalla es destrueix.
  // També marca el controller com a inactiu per evitar actualitzacions posteriors sobre un estat ja eliminat.
  @override
  void dispose() {
    _disposed = true;
    searchController.dispose();
    super.dispose();
  }
}
