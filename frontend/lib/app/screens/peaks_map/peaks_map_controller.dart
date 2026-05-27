import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
import 'package:cims/app/screens/peaks_catalog/models/peaks_filter_state.dart';
import 'package:cims/app/screens/peaks_catalog/models/peaks_search_debouncer.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/get_regions_usecase.dart';
import 'package:cims/core/usecase/peak_status/get_user_peak_statuses_usecase.dart';
import 'package:cims/core/usecase/peak_status/update_peak_status_usecase.dart';
import 'package:cims/core/usecase/peaks/get_map_peaks_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum defineix les navegacions que pot demanar la pantalla del mapa.
// La vista les consumeix i executa la ruta corresponent.
enum PeaksMapDestination {
  none,
  peakDetail,
}

// Aquest controller gestiona la pantalla del mapa de cims.
// Carrega dades, aplica cerca i filtres, controla la selecció i prepara la navegació al detall.
class PeaksMapController extends ChangeNotifier {
  // Aquest constructor prepara les dependències i escolta els estats compartits.
  // També permet obrir el mapa amb un cim inicial ja seleccionat.
  PeaksMapController({
    this.initialPeakId,
    GetMapPeaksUseCase? getMapPeaksUseCase,
    GetRegionsUseCase? getRegionsUseCase,
    GetUserPeakStatusesUseCase? getUserPeakStatusesUseCase,
    UpdatePeakStatusUseCase? updatePeakStatusUseCase,
    PeakStatusStore? peakStatusStore,
    UserStatsRefreshStore? userStatsRefreshStore,
  })  : _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore {
    final apiClient = ApiClientImpl();

    _getMapPeaksUseCase =
        getMapPeaksUseCase ?? GetMapPeaksUseCase(apiClient: apiClient);
    _getRegionsUseCase =
        getRegionsUseCase ?? GetRegionsUseCase(apiClient: apiClient);
    _getUserPeakStatusesUseCase =
        getUserPeakStatusesUseCase ?? GetUserPeakStatusesUseCase(apiClient);
    _updatePeakStatusUseCase =
        updatePeakStatusUseCase ?? UpdatePeakStatusUseCase(apiClient);

    _peakStatusStore.addListener(_onStoreChanged);
    _filtersState.addListener(_onFiltersChanged);
  }

  // Aquest identificador permet seleccionar un cim automàticament en obrir el mapa.
  final int? initialPeakId;

  // Aquestes dependències permeten obtenir cims, regions, estats personals i actualitzar-los.
  late final GetMapPeaksUseCase _getMapPeaksUseCase;
  late final GetRegionsUseCase _getRegionsUseCase;
  late final GetUserPeakStatusesUseCase _getUserPeakStatusesUseCase;
  late final UpdatePeakStatusUseCase _updatePeakStatusUseCase;
  final PeakStatusStore _peakStatusStore;

  // Aquest store avisa altres pantalles que les dades de progrés poden haver canviat.
  final UserStatsRefreshStore _userStatsRefreshStore;

  final searchController = TextEditingController();

  // Aquestes dades representen l’estat visible del mapa.
  // La pantalla les utilitza per mostrar càrrega, errors, cims visibles i filtres disponibles.
  bool isLoading = false;
  bool isUpdatingSelectedPeakStatus = false;
  String? errorMessage;
  List<Peak> peaks = const [];
  List<Peak> _loadedPeaks = const [];
  List<Region> availableRegions = const [];

  // Aquest estat compartit manté els filtres comuns entre catàleg i mapa.
  final PeaksFilterState _filtersState = PeaksFilterState.shared;

  // Aquest valor representa el cim seleccionat al mapa.
  Peak? selectedPeak;

  // Aquestes dades controlen el cicle intern del controller.
  // Serveixen per gestionar cerca, selecció inicial, respostes obsoletes i navegació pendent.
  bool _disposed = false;
  bool _hasAppliedInitialPeak = false;
  final _searchDebouncer = PeaksSearchDebouncer();
  int _loadRequestId = 0;
  int? _selectedPeakId;

  PeaksMapDestination _destination = PeaksMapDestination.none;
  PeaksMapDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Aquest getter retorna el text actual de cerca sense espais sobrants.
  String get currentSearch => searchController.text.trim();

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
  PeakStatus? statusForPeak(int peakId) {
    return _peakStatusStore.getStatus(peakId);
  }

  // Aquest mètode carrega les dades inicials del mapa.
  // Regions, estats personals i cims es demanen en paral·lel perquè són dades independents.
  Future<void> initialize() async {
    await Future.wait([
      _loadRegions().catchError((error, stack) {
        debugPrint('[PeaksMapController] initialize/_loadRegions '
            'escaped: $error\n$stack');
      }),
      _loadUserPeakStatuses().catchError((error, stack) {
        debugPrint('[PeaksMapController] initialize/_loadUserPeakStatuses '
            'escaped: $error\n$stack');
      }),
      _loadPeaks().catchError((error, stack) {
        debugPrint('[PeaksMapController] initialize/_loadPeaks '
            'escaped: $error\n$stack');
      }),
    ]);
  }

  // Aquest mètode carrega les regions disponibles per al filtre del mapa.
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
        '[PeaksMapController] _loadRegions failed '
        '(${error.runtimeType}): $error\n$stack',
      );
      availableRegions = const [];
      notifyListeners();
    }
  }

  // Aquest mètode carrega els estats personals de l’usuari.
  // Els desa al store compartit perquè mapa, catàleg i detall utilitzin la mateixa font.
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
        '[PeaksMapController] _loadUserPeakStatuses failed '
        '(${error.runtimeType}): $error\n$stack',
      );
      _peakStatusStore.clear();
    }
  }

  // Aquest mètode reacciona als canvis del camp de cerca.
  // Aplica una espera breu per evitar una petició al backend per cada tecla.
  void onSearchChanged(String value) {
    errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    _searchDebouncer.run(value, (search) {
      return _loadPeaks(
        search: search,
      );
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

  // Aquest mètode elimina tots els filtres actius.
  Future<void> clearFilters() async {
    _filtersState.clear();
  }

  // Aquest mètode reintenta la càrrega dels cims amb la cerca i els filtres actuals.
  Future<void> onRetryTap() {
    return _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode desa el cim seleccionat al mapa.
  // La selecció permet mostrar la targeta resum i accions ràpides.
  void onPeakSelected(Peak peak) {
    selectedPeak = peak;
    notifyListeners();
  }

  // Aquest mètode activa o desactiva el cim seleccionat com a objectiu.
  Future<void> onSelectedPeakTargetTap() async {
    final peak = selectedPeak;

    if (peak == null || isUpdatingSelectedPeakStatus) {
      return;
    }

    final currentStatus =
        _peakStatusStore.getStatus(peak.id) ?? PeakStatus.emptyForPeak(peak.id);

    await _updateSelectedPeakStatus(
      peakId: peak.id,
      isTarget: !currentStatus.isTarget,
    );
  }

  // Aquest mètode activa o desactiva el cim seleccionat com a preferit.
  Future<void> onSelectedPeakFavoriteTap() async {
    final peak = selectedPeak;

    if (peak == null || isUpdatingSelectedPeakStatus) {
      return;
    }

    final currentStatus =
        _peakStatusStore.getStatus(peak.id) ?? PeakStatus.emptyForPeak(peak.id);

    await _updateSelectedPeakStatus(
      peakId: peak.id,
      isFavorite: !currentStatus.isFavorite,
    );
  }

  // Aquest mètode actualitza un estat manual del cim seleccionat.
  // Quan el backend confirma el canvi, actualitza el store i avisa les estadístiques.
  Future<void> _updateSelectedPeakStatus({
    required int peakId,
    bool? isTarget,
    bool? isFavorite,
  }) async {
    isUpdatingSelectedPeakStatus = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updatedStatus = await _updatePeakStatusUseCase.execute(
        peakId: peakId,
        isTarget: isTarget,
        isFavorite: isFavorite,
      );

      if (_disposed) {
        return;
      }

      _peakStatusStore.setStatus(updatedStatus);
      _userStatsRefreshStore.notifyStatsChanged();
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      errorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      errorMessage = 'No s\'ha pogut actualitzar l\'estat del cim';
    } finally {
      if (!_disposed) {
        isUpdatingSelectedPeakStatus = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode prepara la navegació cap al detall del cim seleccionat.
  void onSelectedPeakDetailTap() {
    final peak = selectedPeak;
    if (peak == null) {
      return;
    }

    _selectedPeakId = peak.id;
    _destination = PeaksMapDestination.peakDetail;
    notifyListeners();
  }

  // Aquest mètode neteja la navegació pendent després que la vista l’hagi resolt.
  void consumeNavigation() {
    _destination = PeaksMapDestination.none;
    _selectedPeakId = null;
  }

  // Aquest mètode carrega els cims preparats per al mapa.
  // Envia cerca i filtres al backend, i després conserva només els cims amb coordenades.
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
      final loadedPeaks = await _getMapPeaksUseCase.execute(
        search: search,
        regionId: selectedRegionId,
        minAltitude: minAltitude,
        maxAltitude: maxAltitude,
        status: selectedStatusFilter.toQueryParam(),
      );

      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      _loadedPeaks = loadedPeaks;
      _applyLocalFilters();
      _applyInitialPeakSelection();
    } on ApiException catch (error) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      _loadedPeaks = const [];
      peaks = const [];
      selectedPeak = null;
      errorMessage = error.message;
    } catch (_) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      _loadedPeaks = const [];
      peaks = const [];
      selectedPeak = null;
      errorMessage = 'No s\'ha pogut carregar el mapa de cims';
    } finally {
      if (!_disposed && requestId == _loadRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode aplica els filtres locals necessaris per renderitzar el mapa.
  // La resta de filtres ja arriben resolts des del backend.
  void _applyLocalFilters() {
    final filteredPeaks =
        _loadedPeaks.where((peak) => peak.hasMapPosition).toList();

    peaks = filteredPeaks;
    _syncSelectedPeak();
  }

  // Aquest mètode aplica la selecció inicial quan el mapa s’obre des del detall.
  // Només s’executa una vegada per evitar reobrir la targeta en cada reconstrucció.
  void _applyInitialPeakSelection() {
    if (_hasAppliedInitialPeak || initialPeakId == null) {
      return;
    }

    _hasAppliedInitialPeak = true;

    final peak = _findPeakById(initialPeakId!);

    if (peak == null || !peak.hasMapPosition) {
      return;
    }

    selectedPeak = peak;
  }

  // Aquest mètode busca un cim dins del llistat visible.
  Peak? _findPeakById(int peakId) {
    for (final peak in peaks) {
      if (peak.id == peakId) {
        return peak;
      }
    }

    return null;
  }

  // Aquest mètode manté coherent la selecció amb els cims visibles.
  // Si el cim seleccionat ja no entra als filtres, es deselecciona.
  void _syncSelectedPeak() {
    final currentSelectedPeak = selectedPeak;
    if (currentSelectedPeak == null) {
      return;
    }

    for (final peak in peaks) {
      if (peak.id == currentSelectedPeak.id) {
        selectedPeak = peak;
        return;
      }
    }

    selectedPeak = null;
  }

  // Aquest mètode tanca la targeta del cim seleccionat.
  void clearSelectedPeak() {
    if (selectedPeak == null) {
      return;
    }

    selectedPeak = null;
    notifyListeners();
  }

  // Aquest mètode reacciona als canvis globals dels estats personals.
  // Si hi ha un filtre d’estat actiu, recarrega els cims perquè la llista pot haver canviat.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    if (selectedStatusFilter != PeakStatusFilter.none) {
      _loadPeaks(
        search: currentSearch.isEmpty ? null : currentSearch,
      );
      return;
    }

    notifyListeners();
  }

  // Aquest mètode reacciona als canvis del filtre compartit.
  // Recarrega el mapa perquè els cims visibles respectin els nous criteris.
  void _onFiltersChanged() {
    if (_disposed) {
      return;
    }

    _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode allibera els recursos quan la pantalla es destrueix.
  // També elimina listeners i cerques pendents.
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
