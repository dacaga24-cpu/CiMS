import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
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

// Aquest valor defineix quants cims es demanen per cada pàgina del catàleg.
// Coincideix amb la mida prevista pel backend i permet carregar el llistat progressivament.
const int _catalogPageSize = 50;

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

    // El controller s'enganxa al store per refrescar el filtre d'estat i la
    // pantalla quan algun altre punt de l'app modifiqui l'estat d'un cim.
    _peakStatusStore.addListener(_onStoreChanged);

    // També s'enganxa al filtre compartit perquè quan l'usuari apliqui un
    // canvi des del mapa, el catàleg refresqui sense necessitat de tornar a
    // entrar a la pantalla. Sense això, cada controller mantenia una còpia
    // pròpia del filtre i les dues pantalles es desincronitzaven.
    _filtersState.addListener(_onFiltersChanged);
  }

  // Aquest bloc guarda els casos d’ús que el controller necessita
  // per obtenir dades del backend sense fer peticions directes des de la pantalla.
  late final GetPeaksPageUseCase _getPeaksPageUseCase;
  late final GetRegionsUseCase _getRegionsUseCase;
  late final GetUserPeakStatusesUseCase _getUserPeakStatusesUseCase;
  final PeakStatusStore _peakStatusStore;

  final searchController = TextEditingController();

  // Aquest bloc representa l’estat visible del catàleg.
  // La pantalla l’utilitza per mostrar càrrega, errors, cims i comarques.
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 0;
  String? errorMessage;
  String? loadMoreErrorMessage;

  // peaks conté la llista final que veu l’usuari. El backend ja aplica
  // tots els filtres (cerca, comarca, altitud, estat); per això la llista
  // visible coincideix exactament amb la que ha retornat l'última pàgina.
  List<Peak> peaks = const [];
  List<Region> availableRegions = const [];

  // Aquest objecte concentra els filtres compartits amb l’altra vista de cims.
  // S'utilitza la instància global PeaksFilterState.shared perquè el filtre
  // sigui coherent entre catàleg i mapa: quan un canvia, l'altre es refresca
  // automàticament gràcies al listener registrat al constructor.
  final PeaksFilterState _filtersState = PeaksFilterState.shared;

  // Aquest bloc guarda informació interna del controller.
  // Serveix per controlar cerques, evitar respostes antigues i preparar navegacions.
  bool _disposed = false;
  final _searchDebouncer = PeaksSearchDebouncer();
  int _loadRequestId = 0;
  int? _selectedPeakId;

  // Ordre actual d'altitud al catàleg. És estat local del controller
  // (no es comparteix al singleton de filtres) perquè l'ordre no afecta
  // el mapa i així evitem refetches innecessaris quan l'usuari el
  // canviï: només el catàleg ho ha de saber. Default `descending` per
  // mantenir el comportament històric (Pica d'Estats primer).
  PeakSortOrder _altitudeSortOrder = PeakSortOrder.descending;
  PeakSortOrder get altitudeSortOrder => _altitudeSortOrder;

  PeaksCatalogDestination _destination = PeaksCatalogDestination.none;
  PeaksCatalogDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Aquest getter resumeix el text de cerca actiu en aquell moment.
  // És útil per reutilitzar-lo en reintents i en missatges de la pantalla.
  String get currentSearch => searchController.text.trim();

  // Helper privat per evitar duplicar el ternari `isEmpty ? null : text`
  // a tots els callsites de `_loadPeaks`. El backend espera `null` quan
  // no hi ha text de cerca (no string buit).
  String? get _searchOrNull => currentSearch.isEmpty ? null : currentSearch;

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
  // Les comarques, els estats personals i la primera pàgina de cims són
  // independents entre elles, així que s’executen en paral·lel per reduir
  // el temps d’espera total a la latència de la crida més lenta. Cada Future
  // captura els seus errors internament; el .catchError d’aquí és una xarxa
  // de seguretat extra perquè un error inesperat en una crida no aborti
  // Future.wait i descarti els resultats de les altres dues.
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
    } catch (error, stack) {
      if (_disposed) {
        return;
      }

      // Es loga el tipus i la traça perquè un canvi de contracte del backend
      // (camps renombrats, format invàlid) no quedi enterrat com a llista buida.
      debugPrint(
        '[PeaksCatalogController] _loadRegions failed '
        '(${error.runtimeType}): $error\n$stack',
      );
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
  // Utilitza un debounce compartit per evitar una petició al backend a cada tecla.
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

  // Aquest mètode aplica els filtres escollits des del panell visual
  // i torna a carregar el catàleg mantenint la cerca actual.
  Future<void> applyFilters({
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
    PeakStatusFilter statusFilter = PeakStatusFilter.none,
  }) async {
    // Apply emet notifyListeners al filtre compartit, i _onFiltersChanged
    // s'encarrega de la recàrrega. Per això aquí no cal cridar _loadPeaks
    // manualment, evitant així una doble petició al backend.
    _filtersState.apply(
      regionId: regionId,
      minAltitude: minAltitude,
      maxAltitude: maxAltitude,
      statusFilter: statusFilter,
    );
  }

  // Aquest mètode elimina els filtres actius i torna a carregar el catàleg.
  // La crida a clear() notifica els listeners si hi havia filtres actius,
  // i la recàrrega es resol per la mateixa via que applyFilters.
  Future<void> clearFilters() async {
    _filtersState.clear();
  }

  // Alterna l'ordre d'altitud entre ascendent i descendent i refresca la
  // primera pàgina del catàleg. Quan canvia l'ordre cal reiniciar la
  // paginació perquè els cims ja carregats correspondrien a l'ordre
  // anterior. Reaprofita `_loadPeaks` que ja s'encarrega de resetejar
  // `currentPage`, `hasMore` i `_loadRequestId`.
  Future<void> toggleAltitudeSortOrder() {
    _altitudeSortOrder = _altitudeSortOrder.toggled();
    return _loadPeaks(
      search: _searchOrNull,
    );
  }

  // Aquest mètode permet tornar a carregar el catàleg amb el text actual.
  // Serveix tant per refrescar la pantalla com per reintentar si hi ha hagut un error.
  Future<void> onRetryTap() {
    return _loadPeaks(
      search: _searchOrNull,
    );
  }

  // Aquest mètode carrega la pàgina següent del catàleg.
  // La pantalla el cridarà quan l’usuari arribi al final del llistat.
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
        sortOrder: _altitudeSortOrder.toQueryParam(),
        page: nextPage,
        pageSize: _catalogPageSize,
      );

      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      // El backend ja aplica tots els filtres; només cal evitar duplicats
      // entre pàgines (per si dues peticions coincidents tornen el mateix
      // cim).
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
    } catch (_) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

      loadMoreErrorMessage = 'No s\'han pogut carregar més cims';
    } finally {
      if (!_disposed && requestId == _loadRequestId) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
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

  // Aquest mètode centralitza la càrrega de la primera pàgina del catàleg.
  // També reinicia la paginació quan canvien la cerca o els filtres.
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
        sortOrder: _altitudeSortOrder.toQueryParam(),
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
    } catch (_) {
      if (_disposed || requestId != _loadRequestId) {
        return;
      }

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

  // Quan el store notifica un canvi (per exemple, l'usuari marca un cim
  // com a favorit des del detall), només cal refetch si hi ha un filtre
  // d'estat actiu, perquè la composició de la llista pot haver canviat
  // (el cim ja entra o ja no entra al filtre). Si no hi ha filtre d'estat,
  // n'hi ha prou amb notificar perquè les cards individuals actualitzin
  // la seva insígnia visual.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    if (selectedStatusFilter != PeakStatusFilter.none) {
      // Fire-and-forget intencional: `_loadPeaks` ja gestiona els seus
      // errors internament i actualitza `errorMessage` per la UI. Marquem
      // amb `unawaited` perquè el linter no s'alarmi i quedi explícit.
      unawaited(_loadPeaks(search: _searchOrNull));
      return;
    }

    notifyListeners();
  }

  // Quan el filtre compartit canvia, es recarrega la primera pàgina del catàleg.
  // Això garanteix que el llistat respecti els nous criteris des del principi.
  void _onFiltersChanged() {
    if (_disposed) {
      return;
    }

    // Mateix raonament que a `_onStoreChanged`: fire-and-forget controlat.
    unawaited(_loadPeaks(search: _searchOrNull));
  }

  // Aquest mètode tanca correctament els recursos del controller quan la pantalla es destrueix.
  // També marca el controller com a inactiu per evitar actualitzacions posteriors sobre un estat ja eliminat.
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
