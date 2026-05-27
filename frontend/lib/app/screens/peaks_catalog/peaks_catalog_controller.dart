import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_sort_by.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_sort_order.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/models/peaks_filter_state.dart';
import 'package:cims/app/screens/peaks_catalog/models/peaks_search_debouncer.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/usecase/get_regions_usecase.dart';
import 'package:cims/core/usecase/peak_status/get_user_peak_statuses_usecase.dart';
import 'package:cims/core/usecase/peaks/get_peaks_page_usecase.dart';
import 'package:flutter/material.dart';

// Aquest valor defineix quants cims es carreguen per pàgina.
// Permet paginar el catàleg sense demanar tots els registres de cop.
const int _catalogPageSize = 50;

// Aquest enum defineix les navegacions que pot demanar el catàleg.
// La pantalla les consumeix i resol la ruta corresponent.
enum PeaksCatalogDestination {
  none,
  peakDetail,
}

// Aquest controller gestiona la pantalla del catàleg de cims.
// Carrega dades, aplica cerca, filtres, ordenació, paginació i navegació al detall.
class PeaksCatalogController extends ChangeNotifier {
  // Aquest constructor prepara les dependències i escolta els estats compartits.
  // Així el catàleg es manté sincronitzat amb el mapa i el detall dels cims.
  PeaksCatalogController({
    GetPeaksPageUseCase? getPeaksPageUseCase,
    GetRegionsUseCase? getRegionsUseCase,
    GetUserPeakStatusesUseCase? getUserPeakStatusesUseCase,
    PeakStatusStore? peakStatusStore,
  }) : _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore {
    final apiClient = ApiClientImpl();

    _getPeaksPageUseCase = getPeaksPageUseCase ??
        GetPeaksPageUseCase(
          apiClient: apiClient,
        );
    _getRegionsUseCase = getRegionsUseCase ??
        GetRegionsUseCase(
          apiClient: apiClient,
        );
    _getUserPeakStatusesUseCase =
        getUserPeakStatusesUseCase ?? GetUserPeakStatusesUseCase(apiClient);

    _peakStatusStore.addListener(_onStoreChanged);
    _filtersState.addListener(_onFiltersChanged);
  }

  // Aquestes dependències permeten obtenir cims, comarques i estats personals.
  late final GetPeaksPageUseCase _getPeaksPageUseCase;
  late final GetRegionsUseCase _getRegionsUseCase;
  late final GetUserPeakStatusesUseCase _getUserPeakStatusesUseCase;
  final PeakStatusStore _peakStatusStore;

  final searchController = TextEditingController();

  // Aquestes dades representen l’estat visible del catàleg.
  // La pantalla les utilitza per mostrar càrrega, errors, llistat i paginació.
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 0;
  String? errorMessage;
  String? loadMoreErrorMessage;
  List<Peak> peaks = const [];
  List<Region> availableRegions = const [];

  // Aquest estat compartit manté els filtres comuns entre catàleg i mapa.
  // Permet que un canvi en una vista es reflecteixi automàticament a l’altra.
  final PeaksFilterState _filtersState = PeaksFilterState.shared;

  // Aquestes dades controlen el cicle intern del controller.
  // Serveixen per gestionar cerca, respostes obsoletes i navegació pendent.
  bool _disposed = false;
  final _searchDebouncer = PeaksSearchDebouncer();
  int _loadRequestId = 0;
  int? _selectedPeakId;

  // Aquestes dades defineixen l’ordre actual del catàleg.
  // L’ordre és local del catàleg perquè no afecta la visualització del mapa.
  PeakSortBy _sortBy = PeakSortBy.altitude;
  PeakSortOrder _sortOrder = PeakSortOrder.descending;
  PeakSortBy get sortBy => _sortBy;
  PeakSortOrder get sortOrder => _sortOrder;

  PeaksCatalogDestination _destination = PeaksCatalogDestination.none;
  PeaksCatalogDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Aquest getter retorna el text de cerca actual sense espais sobrants.
  String get currentSearch => searchController.text.trim();

  // Aquest getter adapta la cerca al format que espera el backend.
  String? get _searchOrNull => currentSearch.isEmpty ? null : currentSearch;

  // Aquests getters exposen els filtres actius a la pantalla.
  int? get selectedRegionId => _filtersState.selectedRegionId;
  int? get minAltitude => _filtersState.minAltitude;
  int? get maxAltitude => _filtersState.maxAltitude;
  PeakStatusFilter get selectedStatusFilter =>
      _filtersState.selectedStatusFilter;

  // Aquest getter indica si hi ha algun filtre aplicat.
  bool get hasActiveFilters => _filtersState.hasActiveFilters;

  // Aquest getter retorna el nom de la comarca seleccionada, si existeix.
  String? get selectedRegionName =>
      _filtersState.selectedRegionName(availableRegions);

  // Aquest getter retorna el nom visible del filtre d’estat seleccionat.
  String? get selectedStatusFilterName => selectedStatusFilter.displayName;

  // Aquest getter construeix el resum visible dels filtres actius.
  String get activeFiltersSummary =>
      _filtersState.activeFiltersSummary(availableRegions);

  // Aquest mètode retorna l’estat personal d’un cim des del store compartit.
  // Això evita mantenir còpies locals desincronitzades.
  PeakStatus? statusForPeak(int peakId) {
    return _peakStatusStore.getStatus(peakId);
  }

  // Aquest mètode carrega les dades inicials del catàleg.
  // Les comarques, els estats i la primera pàgina es demanen en paral·lel.
  Future<void> initialize() async {
    await Future.wait([
      _loadRegions().catchError((error, stack) {
        debugPrint('[PeaksCatalogController] initialize/_loadRegions '
            'escaped: $error\n$stack');
      }),
      _loadUserPeakStatuses().catchError((error, stack) {
        debugPrint('[PeaksCatalogController] initialize/_loadUserPeakStatuses '
            'escaped: $error\n$stack');
      }),
      _loadPeaks().catchError((error, stack) {
        debugPrint('[PeaksCatalogController] initialize/_loadPeaks '
            'escaped: $error\n$stack');
      }),
    ]);
  }

  // Aquest mètode carrega les comarques disponibles per al filtre.
  Future<void> _loadRegions() async {
    try {
      final loadedRegions = await _getRegionsUseCase.execute();

      if (_disposed) {
        return;
      }

      availableRegions = loadedRegions;
      notifyListeners();
    } catch (error, stack) {
      if (_disposed) {
        return;
      }

      debugPrint(
        '[PeaksCatalogController] _loadRegions failed '
        '(${error.runtimeType}): $error\n$stack',
      );
      availableRegions = const [];
      notifyListeners();
    }
  }

  // Aquest mètode carrega els estats personals de l’usuari.
  // Els desa al store compartit perquè totes les pantalles utilitzin la mateixa font.
  Future<void> _loadUserPeakStatuses() async {
    try {
      final statuses = await _getUserPeakStatusesUseCase.execute();

      if (_disposed) {
        return;
      }

      _peakStatusStore.setAll(statuses);
    } catch (error, stack) {
      if (_disposed) {
        return;
      }

      debugPrint(
        '[PeaksCatalogController] _loadUserPeakStatuses failed '
        '(${error.runtimeType}): $error\n$stack',
      );
      _peakStatusStore.clear();
    }
  }

  // Aquest mètode reacciona als canvis del camp de cerca.
  // Aplica una espera breu per evitar una petició per cada tecla.
  void onSearchChanged(String value) {
    errorMessage = null;
    loadMoreErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    _searchDebouncer.run(value, (search) {
      return _loadPeaks(search: search);
    });
  }

  // Aquest mètode aplica els filtres seleccionats.
  // La recàrrega es resol a través del listener del filtre compartit.
  Future<void> applyFilters({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    PeakStatusFilter statusFilter = PeakStatusFilter.none,
  }) async {
    _filtersState.apply(
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
      statusFilter: statusFilter,
    );
  }

  // Aquest mètode elimina els filtres actius.
  // Si hi havia canvis, el filtre compartit notifica la recàrrega del catàleg.
  Future<void> clearFilters() async {
    _filtersState.clear();
  }

  // Aquest mètode actualitza l’ordre del catàleg.
  // Quan canvia el criteri, reinicia la paginació i carrega la primera pàgina.
  Future<void> onSortChanged({
    required PeakSortBy sortBy,
    required PeakSortOrder sortOrder,
  }) {
    if (sortBy == _sortBy && sortOrder == _sortOrder) {
      return Future<void>.value();
    }

    _sortBy = sortBy;
    _sortOrder = sortOrder;
    return _loadPeaks(
      search: _searchOrNull,
    );
  }

  // Aquest mètode permet reintentar o refrescar el catàleg amb l’estat actual.
  Future<void> onRetryTap() {
    return _loadPeaks(
      search: _searchOrNull,
    );
  }

  // Aquest mètode carrega la pàgina següent del catàleg.
  // Conserva els filtres, la cerca i l’ordre aplicats.
  Future<void> loadMorePeaks() async {
    if (isLoading || isLoadingMore || !hasMore) {
      return;
    }

    final requestId = _loadRequestId;
    final nextPage = currentPage + 1;

    isLoadingMore = true;
    loadMoreErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final loadedPage = await _getPeaksPageUseCase.execute(
        search: _searchOrNull,
        regionId: selectedRegionId,
        minAltitude: minAltitude,
        maxAltitude: maxAltitude,
        status: selectedStatusFilter.toQueryParam(),
        sortBy: _sortBy.toQueryParam(),
        sortOrder: _sortOrder.toQueryParam(),
        page: nextPage,
        pageSize: _catalogPageSize,
      );

      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      final existingIds = peaks.map((peak) => peak.id).toSet();
      final newItems =
          loadedPage.items.where((peak) => existingIds.add(peak.id)).toList();

      peaks = [
        ...peaks,
        ...newItems,
      ];
      currentPage = loadedPage.page;
      hasMore = loadedPage.hasMore;
    } on ApiException catch (error) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      loadMoreErrorMessage = error.message;
    } catch (error, stack) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      debugPrint(
        '[PeaksCatalogController] loadMorePeaks unexpected '
        '(${error.runtimeType}): $error\n$stack',
      );
      loadMoreErrorMessage = 'No s\'han pogut carregar més cims';
    } finally {
      if (!_disposed && requestId == _loadRequestId) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode prepara la navegació cap al detall del cim seleccionat.
  void onPeakTap(Peak peak) {
    _selectedPeakId = peak.id;
    _destination = PeaksCatalogDestination.peakDetail;
    notifyListeners();
  }

  // Aquest mètode neteja la navegació pendent després que la vista l’hagi resolt.
  void consumeNavigation() {
    _destination = PeaksCatalogDestination.none;
    _selectedPeakId = null;
  }

  // Aquest mètode carrega la primera pàgina del catàleg.
  // Reinicia la paginació quan canvien cerca, filtres o ordenació.
  Future<void> _loadPeaks({
    String? search,
  }) async {
    final requestId = ++_loadRequestId;

    isLoading = true;
    isLoadingMore = false;
    hasMore = true;
    currentPage = 0;
    errorMessage = null;
    loadMoreErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final loadedPage = await _getPeaksPageUseCase.execute(
        search: search,
        regionId: selectedRegionId,
        minAltitude: minAltitude,
        maxAltitude: maxAltitude,
        status: selectedStatusFilter.toQueryParam(),
        sortBy: _sortBy.toQueryParam(),
        sortOrder: _sortOrder.toQueryParam(),
        page: 1,
        pageSize: _catalogPageSize,
      );

      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      peaks = loadedPage.items;
      currentPage = loadedPage.page;
      hasMore = loadedPage.hasMore;
    } on ApiException catch (error) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      peaks = const [];
      hasMore = false;
      errorMessage = error.message;
    } catch (error, stack) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      debugPrint(
        '[PeaksCatalogController] _loadPeaks unexpected '
        '(${error.runtimeType}): $error\n$stack',
      );
      peaks = const [];
      hasMore = false;
      errorMessage = 'No s\'ha pogut carregar el catàleg de cims';
    } finally {
      if (!_disposed && requestId == _loadRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode reacciona als canvis del store d’estats personals.
  // Si hi ha un filtre d’estat actiu, recarrega el llistat perquè la composició pot haver canviat.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    if (selectedStatusFilter != PeakStatusFilter.none) {
      unawaited(_loadPeaks(search: _searchOrNull));
      return;
    }

    notifyListeners();
  }

  // Aquest mètode reacciona als canvis del filtre compartit.
  // Recarrega la primera pàgina perquè el llistat respecti els nous criteris.
  void _onFiltersChanged() {
    if (_disposed) {
      return;
    }

    unawaited(_loadPeaks(search: _searchOrNull));
  }

  // Aquest mètode allibera recursos quan la pantalla es destrueix.
  // També elimina listeners per evitar notificacions sobre un controller tancat.
  @override
  void dispose() {
    _disposed = true;
    _searchDebouncer.dispose();
    _peakStatusStore.removeListener(_onStoreChanged);
    _filtersState.removeListener(_onFiltersChanged);
    searchController.dispose();
    super.dispose();
  }
}
