import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/app/screens/peaks_catalog/models/peak_status_filter.dart';
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
  // Permet injectar casos d’ús externs en proves o reutilitzar els valors reals
  // de l’aplicació quan no se n’indica cap.
  PeaksMapController({
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
  List<Peak> peaks = const [];
  List<Peak> _loadedPeaks = const [];
  List<Region> availableRegions = const [];

  // Aquest bloc guarda els filtres aplicats actualment al mapa.
  // Permet limitar els cims per regió, altitud o estat personal de l’usuari.
  int? selectedRegionId;
  int? minAltitude;
  int? maxAltitude;
  PeakStatusFilter selectedStatusFilter = PeakStatusFilter.none;

  // Aquest valor representa el cim seleccionat al mapa.
  // Serveix per mostrar-ne informació resumida i permetre l’accés al detall.
  Peak? selectedPeak;

  // Aquest bloc controla situacions internes del controller.
  // Evita actualitzacions després de destruir la pantalla, regula la cerca
  // i descarta respostes antigues quan hi ha diverses càrregues en curs.
  bool _disposed = false;
  Timer? _searchDebounce;
  int _loadRequestId = 0;
  int? _selectedPeakId;

  // Aquest bloc guarda la navegació pendent cap a una altra pantalla.
  // La UI consulta aquests valors i després els consumeix per evitar repetir la navegació.
  PeaksMapDestination _destination = PeaksMapDestination.none;
  PeaksMapDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Retorna el text actual de cerca sense espais sobrants.
  String get currentSearch => searchController.text.trim();

  // Indica si hi ha algun filtre actiu.
  // S’utilitza per mostrar o ocultar el resum de filtres a la pantalla.
  bool get hasActiveFilters =>
      selectedRegionId != null ||
      minAltitude != null ||
      maxAltitude != null ||
      selectedStatusFilter != PeakStatusFilter.none;

  // Retorna el nom de la regió seleccionada a partir del seu identificador.
  // Això permet mostrar un resum entenedor dels filtres aplicats.
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

  // Retorna el text visible del filtre d’estat seleccionat.
  // Si no hi ha cap estat aplicat, no retorna cap etiqueta.
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

  // Construeix un resum breu dels filtres actius.
  // Aquest text ajuda l’usuari a entendre ràpidament per què veu uns cims i no uns altres.
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
  // Aplica una petita espera abans de carregar dades per evitar peticions excessives
  // mentre l’usuari encara està escrivint.
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

  // Aplica els filtres seleccionats per l’usuari.
  // Després de guardar-los, torna a carregar els cims mantenint la cerca actual.
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

  // Elimina tots els filtres aplicats al mapa.
  // Manté la cerca escrita per l’usuari i actualitza el llistat de cims.
  Future<void> clearFilters() async {
    selectedRegionId = null;
    minAltitude = null;
    maxAltitude = null;
    selectedStatusFilter = PeakStatusFilter.none;

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
    _searchDebounce?.cancel();
    _peakStatusStore.removeListener(_onStoreChanged);
    searchController.dispose();
    super.dispose();
  }
}