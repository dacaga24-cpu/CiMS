import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/core/usecase/get_peaks_usecase.dart';
import 'package:cims/core/usecase/get_regions_usecase.dart';
import 'package:cims/core/usecase/get_user_peak_statuses_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum defineix les possibles navegacions de la pantalla del catàleg.
// La vista les consumeix i decideix com resoldre la navegació real.
enum PeaksCatalogDestination {
  none,
  peakDetail,
}

// Aquest controlador gestiona l’estat local de la pantalla del catàleg.
// Carrega els cims reals des del backend, gestiona la cerca, els filtres,
// els estats personals dels cims i prepara la navegació cap al detall
// sense barrejar-la amb la UI.
class PeaksCatalogController extends ChangeNotifier {
  // Aquest constructor prepara els casos d’ús necessaris per carregar
  // el catàleg, les comarques i els estats personals de l’usuari.
  PeaksCatalogController({
    GetPeaksUseCase? getPeaksUseCase,
    GetRegionsUseCase? getRegionsUseCase,
    GetUserPeakStatusesUseCase? getUserPeakStatusesUseCase,
  }) {
    final apiClient = ApiClientImpl();

    _getPeaksUseCase = getPeaksUseCase ??
        GetPeaksUseCase(
          apiClient: apiClient,
        );
    _getRegionsUseCase = getRegionsUseCase ??
        GetRegionsUseCase(
          apiClient: apiClient,
        );
    _getUserPeakStatusesUseCase =
        getUserPeakStatusesUseCase ?? GetUserPeakStatusesUseCase(apiClient);
  }

  // Aquest bloc guarda els casos d’ús que el controller necessita
  // per obtenir dades del backend sense fer peticions directes des de la pantalla.
  late final GetPeaksUseCase _getPeaksUseCase;
  late final GetRegionsUseCase _getRegionsUseCase;
  late final GetUserPeakStatusesUseCase _getUserPeakStatusesUseCase;

  final searchController = TextEditingController();

  // Aquest bloc representa l’estat visible del catàleg.
  // La pantalla l’utilitza per mostrar càrrega, errors, cims, comarques i estats personals.
  bool isLoading = false;
  String? errorMessage;
  List<Peak> peaks = const [];
  List<Peak> _loadedPeaks = const [];
  List<Region> availableRegions = const [];
  Map<int, PeakStatus> statusesByPeakId = {};

  // Aquest bloc manté els filtres actius del catàleg.
  // Es combinen amb la cerca per decidir quins cims s’han de mostrar.
  int? selectedRegionId;
  int? minAltitude;
  int? maxAltitude;
  PeakStatusFilter selectedStatusFilter = PeakStatusFilter.none;

  // Aquest bloc guarda informació interna del controller.
  // Serveix per controlar cerques, evitar respostes antigues i preparar navegacions.
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
      selectedRegionId != null ||
      minAltitude != null ||
      maxAltitude != null ||
      selectedStatusFilter != PeakStatusFilter.none;

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

  // Aquest getter retorna el nom visible del filtre d’estat seleccionat.
  // Si no hi ha filtre d’estat, no aporta cap text al resum.
  String? get selectedStatusFilterName {
    switch (selectedStatusFilter) {
      case PeakStatusFilter.none:
        return null;
      case PeakStatusFilter.pending:
        return 'Pendents';
      case PeakStatusFilter.completed:
        return 'Completats';
      case PeakStatusFilter.target:
        return 'Objectius';
      case PeakStatusFilter.favorite:
        return 'Preferits';
    }
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

    final statusFilterName = selectedStatusFilterName;
    if (statusFilterName != null) {
      parts.add(statusFilterName);
    }

    return parts.join(' · ');
  }

  // Aquest mètode retorna l’estat personal d’un cim concret.
  // La pantalla del catàleg l’utilitzarà per mostrar indicadors visuals
  // a cada targeta sense haver de buscar directament dins del mapa.
  PeakStatus? statusForPeak(int peakId) {
    return statusesByPeakId[peakId];
  }

  // Aquest mètode carrega les dades inicials del catàleg.
  // Primer recupera les comarques i els estats personals, i després
  // carrega els cims que es mostraran a la pantalla.
  Future<void> initialize() async {
    await _loadRegions();
    await _loadUserPeakStatuses();
    await _loadPeaks();
  }

  // Aquest mètode permet refrescar només els estats personals dels cims.
  // Serà útil quan l’usuari torni al catàleg després de modificar un estat
  // des de la pantalla de detall.
  Future<void> reloadStatuses() async {
    await _loadUserPeakStatuses();
    _applyStatusFilter();

    if (!_disposed) {
      notifyListeners();
    }
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

  // Aquest mètode carrega tots els estats personals de l’usuari
  // i els organitza per identificador de cim. Això permet consultar ràpidament
  // si una targeta del catàleg està completada, marcada com a objectiu o preferida.
  Future<void> _loadUserPeakStatuses() async {
    try {
      final statuses = await _getUserPeakStatusesUseCase.execute();

      if (_disposed) {
        return;
      }

      statusesByPeakId = {
        for (final status in statuses) status.peakId: status,
      };
    } catch (_) {
      if (_disposed) {
        return;
      }

      statusesByPeakId = {};
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
    PeakStatusFilter statusFilter = PeakStatusFilter.none,
  }) async {
    selectedRegionId = regionId;
    this.minAltitude = minAltitude;
    this.maxAltitude = maxAltitude;
    selectedStatusFilter = statusFilter;

    await _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode elimina els filtres actius i torna a carregar el catàleg.
  Future<void> clearFilters() async {
    selectedRegionId = null;
    minAltitude = null;
    maxAltitude = null;
    selectedStatusFilter = PeakStatusFilter.none;

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

  // Aquest mètode prepara la navegació cap al detall del cim seleccionat.
  // La pantalla consumirà aquest destí i obrirà la vista corresponent.
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

      _loadedPeaks = loadedPeaks;
      _applyStatusFilter();
    } on ApiException catch (error) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      _loadedPeaks = const [];
      peaks = const [];
      errorMessage = error.message;
    } catch (_) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      _loadedPeaks = const [];
      peaks = const [];
      errorMessage = 'No s\'ha pogut carregar el catàleg de cims';
    } finally {
      if (!_disposed && requestId == _loadRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode aplica el filtre d’estat personal sobre els cims ja carregats.
  // Els filtres de cerca, comarca i altitud venen del backend; l’estat es filtra localment.
  void _applyStatusFilter() {
    if (selectedStatusFilter == PeakStatusFilter.none) {
      peaks = _loadedPeaks;
      return;
    }

    peaks = _loadedPeaks.where(_matchesStatusFilter).toList();
  }

  // Aquest mètode comprova si un cim compleix el filtre d’estat seleccionat.
  bool _matchesStatusFilter(Peak peak) {
    final status = statusesByPeakId[peak.id];

    switch (selectedStatusFilter) {
      case PeakStatusFilter.none:
        return true;
      case PeakStatusFilter.pending:
        return !(status?.isCompleted ?? false);
      case PeakStatusFilter.completed:
        return status?.isCompleted ?? false;
      case PeakStatusFilter.target:
        return status?.isTarget ?? false;
      case PeakStatusFilter.favorite:
        return status?.isFavorite ?? false;
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