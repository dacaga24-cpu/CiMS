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
//
// Els estats personals no es guarden aquí: viuen al PeakStatusStore compartit,
// de manera que qualsevol canvi fet des del detall d'un cim es reflecteix
// automàticament al catàleg sense necessitat de recarregar res.
class PeaksCatalogController extends ChangeNotifier {
  // Aquest constructor prepara els casos d’ús necessaris per carregar
  // el catàleg, les comarques i els estats personals de l’usuari.
  PeaksCatalogController({
    GetPeaksUseCase? getPeaksUseCase,
    GetRegionsUseCase? getRegionsUseCase,
    GetUserPeakStatusesUseCase? getUserPeakStatusesUseCase,
    PeakStatusStore? peakStatusStore,
  }) : _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore {
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

    // El controller s'enganxa al store per refrescar el filtre d'estat i la
    // pantalla quan algun altre punt de l'app modifiqui l'estat d'un cim.
    _peakStatusStore.addListener(_onStoreChanged);
  }

  // Aquest bloc guarda els casos d’ús que el controller necessita
  // per obtenir dades del backend sense fer peticions directes des de la pantalla.
  late final GetPeaksUseCase _getPeaksUseCase;
  late final GetRegionsUseCase _getRegionsUseCase;
  late final GetUserPeakStatusesUseCase _getUserPeakStatusesUseCase;
  final PeakStatusStore _peakStatusStore;

  final searchController = TextEditingController();

  // Aquest bloc representa l’estat visible del catàleg.
  // La pantalla l’utilitza per mostrar càrrega, errors, cims i comarques.
  bool isLoading = false;
  String? errorMessage;
  List<Peak> peaks = const [];
  List<Peak> _loadedPeaks = const [];
  List<Region> availableRegions = const [];

  // Aquest objecte concentra els filtres compartits amb l’altra vista de cims.
  // Així s’evita duplicar la mateixa lògica de resum i estat en dos controllers.
  final _filtersState = PeaksFilterState();

  // Aquest bloc guarda informació interna del controller.
  // Serveix per controlar cerques, evitar respostes antigues i preparar navegacions.
  bool _disposed = false;
  final _searchDebouncer = PeaksSearchDebouncer();
  int _loadRequestId = 0;
  int? _selectedPeakId;

  PeaksCatalogDestination _destination = PeaksCatalogDestination.none;
  PeaksCatalogDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Aquest getter resumeix el text de cerca actiu en aquell moment.
  // És útil per reutilitzar-lo en reintents i en missatges de la pantalla.
  String get currentSearch => searchController.text.trim();

  // Aquest getter exposa la regió seleccionada per mantenir compatible la UI existent.
  int? get selectedRegionId => _filtersState.selectedRegionId;

  // Aquest getter exposa l’altitud mínima seleccionada.
  int? get minAltitude => _filtersState.minAltitude;

  // Aquest getter exposa l’altitud màxima seleccionada.
  int? get maxAltitude => _filtersState.maxAltitude;

  // Aquest getter exposa el filtre d’estat seleccionat.
  PeakStatusFilter get selectedStatusFilter =>
      _filtersState.selectedStatusFilter;

  // Aquest getter indica si hi ha algun filtre aplicat.
  bool get hasActiveFilters => _filtersState.hasActiveFilters;

  // Aquest getter retorna el nom de la comarca seleccionada, si n’hi ha.
  String? get selectedRegionName =>
      _filtersState.selectedRegionName(availableRegions);

  // Aquest getter retorna el nom visible del filtre d’estat seleccionat.
  // Si no hi ha filtre d’estat, no aporta cap text al resum.
  String? get selectedStatusFilterName => selectedStatusFilter.displayName;

  // Aquest getter construeix un resum curt dels filtres actius
  // perquè la pantalla el pugui mostrar sota la barra de cerca.
  String get activeFiltersSummary =>
      _filtersState.activeFiltersSummary(availableRegions);

  // Aquest mètode retorna l’estat personal d’un cim consultant directament el
  // store compartit. Així la pantalla del catàleg sempre veu l'estat més recent
  // sense haver de mantenir cap còpia local.
  PeakStatus? statusForPeak(int peakId) {
    return _peakStatusStore.getStatus(peakId);
  }

  // Aquest mètode carrega les dades inicials del catàleg.
  // Primer recupera les comarques i els estats personals, i després
  // carrega els cims que es mostraran a la pantalla.
  Future<void> initialize() async {
    await _loadRegions();
    await _loadUserPeakStatuses();
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

  // Aquest mètode carrega tots els estats personals de l’usuari
  // i els bolca al store compartit, perquè el catàleg, el detall i qualsevol
  // altra pantalla treballin amb la mateixa font de veritat.
  Future<void> _loadUserPeakStatuses() async {
    try {
      final statuses = await _getUserPeakStatusesUseCase.execute();

      if (_disposed) {
        return;
      }

      _peakStatusStore.setAll(statuses);
    } catch (_) {
      if (_disposed) {
        return;
      }

      _peakStatusStore.clear();
    }
  }

  // Aquest mètode reacciona als canvis del camp de cerca.
  // Utilitza un debounce compartit per evitar una petició al backend a cada tecla.
  void onSearchChanged(String value) {
    errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    _searchDebouncer.run(value, (search) {
      return _loadPeaks(search: search);
    });
  }

  // Aquest mètode aplica els filtres escollits des del panell visual
  // i torna a carregar el catàleg mantenint la cerca actual.
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

    await _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Aquest mètode elimina els filtres actius i torna a carregar el catàleg.
  Future<void> clearFilters() async {
    _filtersState.clear();

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
    final status = _peakStatusStore.getStatus(peak.id);
    return selectedStatusFilter.matches(status);
  }

  // Quan el store notifica un canvi (per exemple, perquè el detall ha
  // actualitzat l'estat d'un cim), s'ha de tornar a aplicar el filtre d'estat
  // perquè la llista visible reflecteixi la nova realitat sense recarregar
  // res del backend.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    _applyStatusFilter();
    notifyListeners();
  }

  // Aquest mètode tanca correctament els recursos del controller quan la pantalla es destrueix.
  // També marca el controller com a inactiu per evitar actualitzacions posteriors sobre un estat ja eliminat.
  @override
  void dispose() {
    _disposed = true;
    _searchDebouncer.dispose();
    _peakStatusStore.removeListener(_onStoreChanged);
    searchController.dispose();
    super.dispose();
  }
}
