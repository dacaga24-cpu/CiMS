import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/usecase/get_peaks_usecase.dart';
import 'package:cims/core/usecase/get_regions_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum defineix les possibles navegacions de la pantalla del catàleg.
// La vista les consumeix i decideix com resoldre la navegació real.
enum PeaksCatalogDestination {
  none,
  peakDetail,
}

// Aquest controlador gestiona l’estat local de la pantalla del catàleg.
// Carrega els cims reals des del backend, gestiona la cerca, els filtres
// i prepara la navegació cap al detall sense barrejar-la amb la UI.
class PeaksCatalogController extends ChangeNotifier {
  PeaksCatalogController({
    GetPeaksUseCase? getPeaksUseCase,
    GetRegionsUseCase? getRegionsUseCase,
  })  : _getPeaksUseCase = getPeaksUseCase ??
            GetPeaksUseCase(
              apiClient: ApiClientImpl(),
            ),
        _getRegionsUseCase = getRegionsUseCase ??
            GetRegionsUseCase(
              apiClient: ApiClientImpl(),
            );

  final GetPeaksUseCase _getPeaksUseCase;
  final GetRegionsUseCase _getRegionsUseCase;
  final searchController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  List<Peak> peaks = const [];
  List<Region> availableRegions = const [];

  int? selectedRegionId;
  int? minAltitude;
  int? maxAltitude;

  bool _disposed = false;
  Timer? _searchDebounce;
  int _loadRequestId = 0;
  int? _selectedPeakId;

  PeaksCatalogDestination _destination = PeaksCatalogDestination.none;
  PeaksCatalogDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Aquest getter resumeix el text de cerca actiu en aquell moment.
  // És útil per reutilitzar-lo en reintents i en missatges de la pantalla.
  String get currentSearch => searchController.text.trim();

  // Aquest getter indica si hi ha algun filtre aplicat.
  bool get hasActiveFilters =>
      selectedRegionId != null || minAltitude != null || maxAltitude != null;

  // Aquest getter retorna el nom de la comarca seleccionada, si n’hi ha.
  String? get selectedRegionName {
    if (selectedRegionId == null) {
      return null;
    }

    for (final region in availableRegions) {
      if (region.id == selectedRegionId) {
        return region.name;
      }
    }

    return null;
  }

  // Aquest getter construeix un resum curt dels filtres actius
  // perquè la pantalla el pugui mostrar sota la barra de cerca.
  String get activeFiltersSummary {
    final parts = <String>[];

    final regionName = selectedRegionName;
    if (regionName != null && regionName.isNotEmpty) {
      parts.add(regionName);
    }

    if (minAltitude != null && maxAltitude != null) {
      parts.add('$minAltitude - $maxAltitude m');
    } else if (minAltitude != null) {
      parts.add('Des de $minAltitude m');
    } else if (maxAltitude != null) {
      parts.add('Fins a $maxAltitude m');
    }

    return parts.join(' · ');
  }

  // Aquest mètode carrega les dades inicials del catàleg.
  // Primer recupera les comarques disponibles i després carrega els cims.
  Future<void> initialize() async {
    await _loadRegions();
    await _loadPeaks();
  }

  // Aquest mètode carrega la llista de comarques disponibles
  // per poder alimentar el filtre del catàleg.
  Future<void> _loadRegions() async {
    try {
      final loadedRegions = await _getRegionsUseCase.execute();

      if (_disposed) {
        return;
      }

      availableRegions = loadedRegions;
      notifyListeners();
    } catch (_) {
      if (_disposed) {
        return;
      }

      availableRegions = const [];
      notifyListeners();
    }
  }

  // Aquest mètode reacciona als canvis del camp de cerca.
  // Aplica un petit debounce per evitar una petició al backend a cada tecla.
  void onSearchChanged(String value) {
    errorMessage = null;
    if (!_disposed) {
      notifyListeners();
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        _loadPeaks(
          search: value.trim().isEmpty ? null : value.trim(),
        );
      },
    );
  }

  // Aquest mètode aplica els filtres escollits des del panell visual
  // i torna a carregar el catàleg mantenint la cerca actual.
  Future<void> applyFilters({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  }) async {
    selectedRegionId = regionId;
    this.minAltitude = minAltitude;
    this.maxAltitude = maxAltitude;

    await _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode elimina els filtres actius i torna a carregar el catàleg.
  Future<void> clearFilters() async {
    selectedRegionId = null;
    minAltitude = null;
    maxAltitude = null;

    await _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode permet tornar a carregar el catàleg amb el text actual.
  // Serveix tant per refrescar la pantalla com per reintentar si hi ha hagut un error.
  Future<void> onRetryTap() {
    return _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode prepara la navegació al detall del cim seleccionat.
  // El detall complet arribarà en una altra tasca, però la navegació ja queda connectada.
  void onPeakTap(Peak peak) {
    _selectedPeakId = peak.id;
    _destination = PeaksCatalogDestination.peakDetail;
    notifyListeners();
  }

  // Aquest mètode reinicia el destí de navegació després que la vista ja l’hagi utilitzat.
  void consumeNavigation() {
    _destination = PeaksCatalogDestination.none;
    _selectedPeakId = null;
  }

  // Aquest mètode centralitza la càrrega real del catàleg.
  // També evita que una resposta antiga sobreescrigui una cerca més recent.
  Future<void> _loadPeaks({
    String? search,
  }) async {
    final requestId = ++_loadRequestId;

    isLoading = true;
    errorMessage = null;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      final loadedPeaks = await _getPeaksUseCase.execute(
        search: search,
        regionId: selectedRegionId,
        minAltitude: minAltitude,
        maxAltitude: maxAltitude,
      );

      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      peaks = loadedPeaks;
    } on ApiException catch (error) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      peaks = const [];
      errorMessage = error.message;
    } catch (_) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      peaks = const [];
      errorMessage = 'No s\'ha pogut carregar el catàleg de cims';
    } finally {
      if (!_disposed && requestId == _loadRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode tanca correctament els recursos del controller quan la pantalla es destrueix.
  // També marca el controller com a inactiu per evitar actualitzacions posteriors sobre un estat ja eliminat.
  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
