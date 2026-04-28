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

// Aquest enum defineix les navegacions possibles des de la pantalla del mapa.
// La vista les consumeix i executa la navegació real.
enum PeaksMapDestination {
  none,
  peakDetail,
}

// Aquest controller gestiona l’estat de la pantalla de mapa de cims.
// Carrega els cims del backend, aplica cerca i filtres, controla la selecció
// d’un cim i prepara la navegació cap al detall sense dependre de la UI.
class PeaksMapController extends ChangeNotifier {
  // Aquest constructor prepara les dependències necessàries per carregar el mapa.
  // També permet rebre un cim inicial quan la pantalla s’obre des del detall.
  PeaksMapController({
    this.initialPeakId,
    GetPeaksUseCase? getPeaksUseCase,
    GetRegionsUseCase? getRegionsUseCase,
    GetUserPeakStatusesUseCase? getUserPeakStatusesUseCase,
    PeakStatusStore? peakStatusStore,
  }) : _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore {
    final apiClient = ApiClientImpl();

    _getPeaksUseCase = getPeaksUseCase ?? GetPeaksUseCase(apiClient: apiClient);
    _getRegionsUseCase =
        getRegionsUseCase ?? GetRegionsUseCase(apiClient: apiClient);
    _getUserPeakStatusesUseCase =
        getUserPeakStatusesUseCase ?? GetUserPeakStatusesUseCase(apiClient);

    _peakStatusStore.addListener(_onStoreChanged);
  }

  // Identificador opcional del cim que s’ha de seleccionar en obrir el mapa.
  final int? initialPeakId;

  // Aquests casos d’ús concentren les operacions de dades que necessita el mapa.
  // El controller els utilitza per obtenir cims, regions i estats personals
  // sense comunicar-se directament amb l’API.
  late final GetPeaksUseCase _getPeaksUseCase;
  late final GetRegionsUseCase _getRegionsUseCase;
  late final GetUserPeakStatusesUseCase _getUserPeakStatusesUseCase;
  final PeakStatusStore _peakStatusStore;

  // Aquest controller gestiona el text de cerca introduït per l’usuari.
  final searchController = TextEditingController();

  // Aquest bloc manté l’estat principal de la pantalla.
  // Inclou la càrrega, els possibles errors, els cims visibles al mapa
  // i les regions disponibles per aplicar filtres.
  bool isLoading = false;
  String? errorMessage;
  // peaks conté els cims finals que es poden mostrar al mapa.
  // _loadedPeaks conserva els cims retornats pel backend abans d’aplicar filtres locals.
  List<Peak> peaks = const [];
  List<Peak> _loadedPeaks = const [];
  List<Region> availableRegions = const [];

  // Aquest objecte concentra els filtres compartits amb l’altra vista de cims.
  // Així s’evita duplicar la mateixa lògica de resum i estat en dos controllers.
  final _filtersState = PeaksFilterState();

  // Aquest valor representa el cim seleccionat al mapa.
  // Serveix per mostrar-ne informació resumida i permetre l’accés al detall.
  Peak? selectedPeak;

  // Aquest bloc controla situacions internes del controller.
  // Evita actualitzacions després de destruir la pantalla, regula la cerca
  // i descarta respostes antigues quan hi ha diverses càrregues en curs.
  bool _disposed = false;
  bool _hasAppliedInitialPeak = false;
  final _searchDebouncer = PeaksSearchDebouncer();
  int _loadRequestId = 0;
  int? _selectedPeakId;

  // Aquest bloc guarda la navegació pendent cap a una altra pantalla.
  // La UI consulta aquests valors i després els consumeix per evitar repetir la navegació.
  PeaksMapDestination _destination = PeaksMapDestination.none;
  PeaksMapDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Retorna el text actual de cerca sense espais sobrants.
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

  // Indica si hi ha algun filtre actiu.
  // S’utilitza per mostrar o ocultar el resum de filtres a la pantalla.
  bool get hasActiveFilters => _filtersState.hasActiveFilters;

  // Retorna el nom de la regió seleccionada a partir del seu identificador.
  // Això permet mostrar un resum entenedor dels filtres aplicats.
  String? get selectedRegionName =>
      _filtersState.selectedRegionName(availableRegions);

  // Retorna el text visible del filtre d’estat seleccionat.
  // Si no hi ha cap estat aplicat, no retorna cap etiqueta.
  String? get selectedStatusFilterName => selectedStatusFilter.displayName;

  // Construeix un resum breu dels filtres actius.
  // Aquest text ajuda l’usuari a entendre ràpidament per què veu uns cims i no uns altres.
  String get activeFiltersSummary =>
      _filtersState.activeFiltersSummary(availableRegions);

  // Retorna l’estat personal d’un cim concret.
  // La pantalla ho pot utilitzar per representar si és assolit, objectiu o favorit.
  PeakStatus? statusForPeak(int peakId) {
    return _peakStatusStore.getStatus(peakId);
  }

  // Inicialitza les dades necessàries per mostrar el mapa.
  // Primer carrega les regions i els estats personals, i després obté els cims visibles.
  Future<void> initialize() async {
    await _loadRegions();
    await _loadUserPeakStatuses();
    await _loadPeaks();
  }

  // Carrega les regions disponibles per als filtres del mapa.
  // Si no es poden obtenir, deixa la llista buida perquè la pantalla pugui continuar funcionant.
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

  // Carrega els estats personals dels cims de l’usuari.
  // Aquesta informació és necessària per filtrar i mostrar cims completats,
  // objectius o preferits dins del mapa.
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

  // Gestiona els canvis en el camp de cerca.
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

  // Aplica els filtres seleccionats per l’usuari.
  // Després de guardar-los, torna a carregar els cims mantenint la cerca actual.
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

  // Elimina tots els filtres aplicats al mapa.
  // Manté la cerca escrita per l’usuari i actualitza el llistat de cims.
  Future<void> clearFilters() async {
    _filtersState.clear();

    await _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Torna a intentar carregar els cims quan s’ha produït un error.
  // Manté la cerca actual per respectar el context de l’usuari.
  Future<void> onRetryTap() {
    return _loadPeaks(
      search: currentSearch.isEmpty ? null : currentSearch,
    );
  }

  // Desa el cim seleccionat per l’usuari dins del mapa.
  // Aquesta selecció permet mostrar accions o informació associada al cim.
  void onPeakSelected(Peak peak) {
    selectedPeak = peak;
    notifyListeners();
  }

  // Prepara la navegació cap al detall del cim seleccionat.
  // Si no hi ha cap cim seleccionat, no fa cap acció.
  void onSelectedPeakDetailTap() {
    final peak = selectedPeak;
    if (peak == null) {
      return;
    }

    _selectedPeakId = peak.id;
    _destination = PeaksMapDestination.peakDetail;
    notifyListeners();
  }

  // Neteja la navegació pendent un cop la pantalla ja l’ha executat.
  // Això evita que la mateixa navegació es repeteixi en reconstruccions posteriors.
  void consumeNavigation() {
    _destination = PeaksMapDestination.none;
    _selectedPeakId = null;
  }

  // Carrega els cims segons la cerca i els filtres actuals.
  // També controla els errors i evita que una resposta antiga sobreescrigui dades més recents.
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

  // Aplica els filtres que es poden resoldre dins del frontend.
  // També descarta els cims sense coordenades, ja que no es poden representar al mapa.
  void _applyLocalFilters() {
    final filteredPeaks = _loadedPeaks
        .where((peak) => peak.hasMapPosition)
        .where(_matchesStatusFilter)
        .toList();

    peaks = filteredPeaks;
    _syncSelectedPeak();
  }

  // Comprova si un cim compleix el filtre d’estat seleccionat.
  // Aquesta validació permet mostrar només pendents, completats, objectius o preferits.
  bool _matchesStatusFilter(Peak peak) {
    final status = _peakStatusStore.getStatus(peak.id);
    return selectedStatusFilter.matches(status);
  }

  // Aplica la selecció inicial quan la pantalla s’obre des del detall d’un cim.
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

  // Busca un cim dins del llistat carregat.
  // Es fa servir per connectar la navegació des del detall amb la pantalla de mapa.
  Peak? _findPeakById(int peakId) {
    for (final peak in peaks) {
      if (peak.id == peakId) {
        return peak;
      }
    }

    return null;
  }

  // Manté la selecció del cim coherent amb la llista filtrada.
  // Si el cim seleccionat ja no és visible pels filtres actuals, es deselecciona.
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

  // Aquest mètode neteja el cim seleccionat al mapa.
  // S'utilitza quan l'usuari toca una zona buida del mapa i vol tancar la targeta flotant.
  void clearSelectedPeak() {
    if (selectedPeak == null) {
      return;
    }

    selectedPeak = null;
    notifyListeners();
  }

  // Reacciona als canvis globals dels estats dels cims.
  // Quan un estat canvia, recalcula els filtres locals perquè el mapa mostri dades actualitzades.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    _applyLocalFilters();
    notifyListeners();
  }

  // Allibera els recursos del controller quan la pantalla deixa d’utilitzar-lo.
  // Això evita escoltes actives, temporitzadors pendents i possibles actualitzacions innecessàries.
  @override
  void dispose() {
    _disposed = true;
    _searchDebouncer.dispose();
    _peakStatusStore.removeListener(_onStoreChanged);
    searchController.dispose();
    super.dispose();
  }
}
