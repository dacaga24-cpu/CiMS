import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/entity/peak_weather.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/ascents/get_ascents_by_peak_usecase.dart';
import 'package:cims/core/usecase/peaks/get_peak_by_id_usecase.dart';
import 'package:cims/core/usecase/peaks/get_peak_daily_weather_usecase.dart';
import 'package:cims/core/usecase/peaks/get_peak_hourly_weather_usecase.dart';
import 'package:cims/core/usecase/peaks/get_peak_status_usecase.dart';
import 'package:cims/core/usecase/peak_status/update_peak_status_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum defineix les accions de navegació que la vista ha de resoldre.
// Manté el controller separat del context visual i de les rutes concretes.
enum PeakDetailDestination {
  none,
  openMap,
  registerAscent,
  ascentHistory,
}

// Aquest controller gestiona la pantalla de detall d’un cim.
// Carrega el cim, l’estat personal, les ascensions i la previsió meteorològica.
class PeakDetailController extends ChangeNotifier {
  // Aquest constructor prepara les dependències necessàries per carregar el detall del cim.
  // Permet injectar casos d’ús en proves o utilitzar les implementacions reals per defecte.
  factory PeakDetailController({
    required int peakId,
    ApiClient? apiClient,
    GetPeakByIdUseCase? getPeakByIdUseCase,
    GetPeakStatusUseCase? getPeakStatusUseCase,
    UpdatePeakStatusUseCase? updatePeakStatusUseCase,
    GetAscentsByPeakUseCase? getAscentsByPeakUseCase,
    GetPeakDailyWeatherUseCase? getPeakDailyWeatherUseCase,
    GetPeakHourlyWeatherUseCase? getPeakHourlyWeatherUseCase,
    PeakStatusStore? peakStatusStore,
    UserStatsRefreshStore? userStatsRefreshStore,
  }) {
    final resolvedApiClient = apiClient ?? ApiClientImpl();

    return PeakDetailController._(
      peakId: peakId,
      getPeakByIdUseCase: getPeakByIdUseCase ??
          GetPeakByIdUseCase(
            apiClient: resolvedApiClient,
          ),
      getPeakStatusUseCase:
          getPeakStatusUseCase ?? GetPeakStatusUseCase(resolvedApiClient),
      updatePeakStatusUseCase:
          updatePeakStatusUseCase ?? UpdatePeakStatusUseCase(resolvedApiClient),
      getAscentsByPeakUseCase:
          getAscentsByPeakUseCase ?? GetAscentsByPeakUseCase(resolvedApiClient),
      getPeakDailyWeatherUseCase: getPeakDailyWeatherUseCase ??
          GetPeakDailyWeatherUseCase(
            apiClient: resolvedApiClient,
          ),
      getPeakHourlyWeatherUseCase: getPeakHourlyWeatherUseCase ??
          GetPeakHourlyWeatherUseCase(
            apiClient: resolvedApiClient,
          ),
      peakStatusStore: peakStatusStore ?? AppSession.peakStatusStore,
      userStatsRefreshStore:
          userStatsRefreshStore ?? AppSession.userStatsRefreshStore,
    );
  }

  // Aquest constructor intern rep les dependències ja resoltes.
  // Separa la creació d’objectes de la lògica principal del controller.
  PeakDetailController._({
    required this.peakId,
    required GetPeakByIdUseCase getPeakByIdUseCase,
    required GetPeakStatusUseCase getPeakStatusUseCase,
    required UpdatePeakStatusUseCase updatePeakStatusUseCase,
    required GetAscentsByPeakUseCase getAscentsByPeakUseCase,
    required GetPeakDailyWeatherUseCase getPeakDailyWeatherUseCase,
    required GetPeakHourlyWeatherUseCase getPeakHourlyWeatherUseCase,
    required PeakStatusStore peakStatusStore,
    required UserStatsRefreshStore userStatsRefreshStore,
  })  : _getPeakByIdUseCase = getPeakByIdUseCase,
        _getPeakStatusUseCase = getPeakStatusUseCase,
        _updatePeakStatusUseCase = updatePeakStatusUseCase,
        _getAscentsByPeakUseCase = getAscentsByPeakUseCase,
        _getPeakDailyWeatherUseCase = getPeakDailyWeatherUseCase,
        _getPeakHourlyWeatherUseCase = getPeakHourlyWeatherUseCase,
        _peakStatusStore = peakStatusStore,
        _userStatsRefreshStore = userStatsRefreshStore {
    _peakStatusStore.addListener(_onStoreChanged);
  }

  // Aquestes dependències permeten carregar el cim, consultar-ne l’estat,
  // actualitzar marques personals, llegir ascensions i obtenir la previsió.
  final int peakId;
  final GetPeakByIdUseCase _getPeakByIdUseCase;
  final GetPeakStatusUseCase _getPeakStatusUseCase;
  final UpdatePeakStatusUseCase _updatePeakStatusUseCase;
  final GetAscentsByPeakUseCase _getAscentsByPeakUseCase;
  final GetPeakDailyWeatherUseCase _getPeakDailyWeatherUseCase;
  final GetPeakHourlyWeatherUseCase _getPeakHourlyWeatherUseCase;
  final PeakStatusStore _peakStatusStore;

  // Aquest store avisa altres pantalles que les dades de progrés poden haver canviat.
  // Permet refrescar dashboard i estadístiques després de modificar un estat.
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquestes dades representen l’estat principal de la pantalla.
  // La vista les utilitza per mostrar càrrega, errors i informació del cim.
  bool isLoading = false;
  bool isUpdatingStatus = false;
  String? errorMessage;
  String? statusErrorMessage;
  String? ascentsErrorMessage;
  Peak? peak;
  DateTime? lastAscentDate;

  // Aquestes dades representen l’estat de la previsió meteorològica.
  // Es mantenen separades perquè el clima no bloquegi el detall del cim.
  bool isWeatherLoading = false;
  String? weatherErrorMessage;
  PeakWeather? weatherForecast;

  // Aquest comptador evita aplicar respostes meteorològiques obsoletes.
  // Només l’última càrrega pot modificar l’estat visible.
  int _weatherLoadId = 0;

  // Aquest comptador identifica la càrrega vigent del detall del cim.
  // Evita que respostes antigues actualitzin la pantalla després d’un reintent.
  int _peakLoadId = 0;

  // Aquestes estructures mantenen la previsió horària per dia.
  // Cada data conserva dades, càrrega i error de manera independent.
  final Map<String, PeakHourlyWeather> _hourlyByDay = {};
  final Set<String> _hourlyLoadingDays = {};
  final Map<String, String> _hourlyErrorByDay = {};

  // Aquest comptador controla les càrregues horàries de cada dia.
  // Permet descartar una resposta antiga si l’usuari torna a obrir el mateix dia.
  final Map<String, int> _hourlyLoadIdByDay = {};

  // Aquesta data indica quin dia té el panell horari desplegat.
  String? _expandedDay;
  String? get expandedDay => _expandedDay;

  // Aquests mètodes exposen el cache horari sense permetre modificar-lo des de la UI.
  PeakHourlyWeather? hourlyForDay(String date) => _hourlyByDay[date];
  bool isHourlyLoading(String date) => _hourlyLoadingDays.contains(date);
  String? hourlyErrorFor(String date) => _hourlyErrorByDay[date];

  // L’estat personal del cim es llegeix sempre del store compartit.
  // Això evita còpies locals que es puguin desincronitzar entre pantalles.
  PeakStatus? get peakStatus => _peakStatusStore.getStatus(peakId);

  // Aquestes dades controlen el cicle de vida del controller i la navegació pendent.
  bool _disposed = false;
  PeakDetailDestination _destination = PeakDetailDestination.none;

  PeakDetailDestination get destination => _destination;

  // Aquest mètode inicia la càrrega del detall del cim.
  Future<void> initialize() {
    return _loadPeak();
  }

  // Aquest mètode permet reintentar la càrrega principal.
  Future<void> onRetryTap() {
    return _loadPeak();
  }

  // Aquesta acció activa o desactiva el cim com a objectiu personal.
  Future<void> onTargetTap() {
    final currentStatus = peakStatus ?? PeakStatus.emptyForPeak(peakId);

    return _updateStatus(
      isTarget: !currentStatus.isTarget,
    );
  }

  // Aquesta acció activa o desactiva el cim com a preferit.
  Future<void> onFavoriteTap() {
    final currentStatus = peakStatus ?? PeakStatus.emptyForPeak(peakId);

    return _updateStatus(
      isFavorite: !currentStatus.isFavorite,
    );
  }

  // Aquesta acció prepara l’obertura del mapa.
  void onMapTap() {
    _destination = PeakDetailDestination.openMap;
    notifyListeners();
  }

  // Aquesta acció prepara la navegació cap al registre d’una ascensió.
  void onRegisterAscentTap() {
    _destination = PeakDetailDestination.registerAscent;
    notifyListeners();
  }

  // Aquesta acció prepara la navegació cap a l’historial d’ascensions del cim.
  void onAscentHistoryTap() {
    _destination = PeakDetailDestination.ascentHistory;
    notifyListeners();
  }

  // Aquest mètode neteja la navegació pendent després que la vista l’hagi resolt.
  void consumeNavigation() {
    _destination = PeakDetailDestination.none;
  }

  // Aquest mètode recupera l’última ascensió registrada per l’usuari en aquest cim.
  // Utilitza el loadId per evitar aplicar resultats d’una càrrega anterior.
  Future<void> refreshLastAscentDate({int? loadId}) async {
    final requestId = loadId ?? _peakLoadId;

    try {
      final ascents = await _getAscentsByPeakUseCase(peakId);

      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      lastAscentDate = ascents.isEmpty ? null : ascents.first.ascentDate;
      ascentsErrorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      ascentsErrorMessage = error.message;
      notifyListeners();
    } catch (error, stack) {
      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      debugPrint(
        '[PeakDetailController] refreshLastAscentDate failed '
        '(${error.runtimeType}): $error\n$stack',
      );
      ascentsErrorMessage = 'No s\'han pogut carregar les ascensions del cim';
      notifyListeners();
    }
  }

  // Aquest mètode carrega el detall principal del cim.
  // També inicia en paral·lel la càrrega d’estat, ascensions i meteorologia.
  Future<void> _loadPeak() async {
    final requestId = ++_peakLoadId;

    isLoading = true;
    errorMessage = null;
    statusErrorMessage = null;
    ascentsErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    unawaited(_loadWeather());
    unawaited(_refreshPeakStatusFromBackend(loadId: requestId));
    unawaited(refreshLastAscentDate(loadId: requestId));

    try {
      final loadedPeak = await _getPeakByIdUseCase.execute(peakId);

      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      peak = loadedPeak;
    } on ApiException catch (error) {
      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      peak = null;
      errorMessage = error.message;
    } catch (_) {
      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      peak = null;
      errorMessage = 'No s\'ha pogut carregar el detall del cim';
    } finally {
      if (!_disposed && requestId == _peakLoadId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode carrega la previsió meteorològica diària del cim.
  // Si falla, només afecta la targeta del clima i no bloqueja la resta de pantalla.
  Future<void> _loadWeather() async {
    final loadId = ++_weatherLoadId;
    isWeatherLoading = true;
    weatherErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final forecast = await _getPeakDailyWeatherUseCase.execute(peakId);

      if (_disposed || loadId != _weatherLoadId) {
        return;
      }

      weatherForecast = forecast;
    } on ApiException catch (error) {
      if (_disposed || loadId != _weatherLoadId) {
        return;
      }

      weatherForecast = null;
      weatherErrorMessage = error.message;
    } catch (error, stackTrace) {
      if (_disposed || loadId != _weatherLoadId) {
        return;
      }

      debugPrint(
        '[weather] load failed: ${error.runtimeType} — $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      weatherForecast = null;
      weatherErrorMessage = 'No s\'ha pogut carregar la previsió meteorològica';
    } finally {
      if (!_disposed && loadId == _weatherLoadId) {
        isWeatherLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode reintenta només la càrrega meteorològica.
  // Evita haver de recarregar tot el detall del cim.
  Future<void> onWeatherRetryTap() {
    return _loadWeather();
  }

  // Aquest mètode obre o tanca el panell horari d’un dia.
  // Si les hores ja estan carregades i no hi ha error, reutilitza el cache.
  Future<void> toggleDayExpansion(String date) async {
    if (date.isEmpty) {
      return;
    }

    if (_expandedDay == date) {
      _expandedDay = null;
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }

    _expandedDay = date;

    if (!_disposed) {
      notifyListeners();
    }

    final cached = _hourlyByDay[date];
    final hasError = _hourlyErrorByDay.containsKey(date);
    if (cached != null && !hasError) {
      return;
    }
    await _loadHourlyFor(date);
  }

  // Aquest mètode reintenta la previsió horària d’un dia concret.
  // No afecta la previsió diària ni la resta de dies ja carregats.
  Future<void> onHourlyRetryTap(String date) {
    return _loadHourlyFor(date);
  }

  // Aquest mètode carrega la previsió horària d’una data concreta.
  // Cada dia manté el seu propi estat de càrrega i error.
  Future<void> _loadHourlyFor(String date) async {
    if (date.isEmpty) {
      return;
    }

    final loadId = (_hourlyLoadIdByDay[date] ?? 0) + 1;
    _hourlyLoadIdByDay[date] = loadId;
    _hourlyLoadingDays.add(date);
    _hourlyErrorByDay.remove(date);

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final hourly = await _getPeakHourlyWeatherUseCase.execute(peakId, date);

      if (_disposed || _hourlyLoadIdByDay[date] != loadId) {
        return;
      }

      _hourlyByDay[date] = hourly;
    } on ApiException catch (error) {
      if (_disposed || _hourlyLoadIdByDay[date] != loadId) {
        return;
      }

      _hourlyErrorByDay[date] = error.message;
    } catch (error, stackTrace) {
      if (_disposed || _hourlyLoadIdByDay[date] != loadId) {
        return;
      }

      debugPrint(
        '[weather] hourly load failed for $date: ${error.runtimeType} — $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      _hourlyErrorByDay[date] = 'No s\'ha pogut carregar la previsió horària';
    } finally {
      if (!_disposed && _hourlyLoadIdByDay[date] == loadId) {
        _hourlyLoadingDays.remove(date);
        notifyListeners();
      }
    }
  }

  // Aquest mètode consulta l’estat personal del cim al backend i el desa al store.
  // Si falla, conserva l’estat local existent i guarda un error específic.
  Future<void> _refreshPeakStatusFromBackend({int? loadId}) async {
    final requestId = loadId ?? _peakLoadId;

    try {
      final loadedStatus = await _getPeakStatusUseCase.execute(peakId);

      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      statusErrorMessage = null;
      _peakStatusStore.setStatus(loadedStatus);
      notifyListeners();
    } on ApiException catch (error) {
      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      statusErrorMessage = error.message;
      notifyListeners();
    } catch (error, stack) {
      if (_disposed || requestId != _peakLoadId) {
        return;
      }

      debugPrint(
        '[PeakDetailController] _refreshPeakStatusFromBackend failed '
        '(${error.runtimeType}): $error\n$stack',
      );
      statusErrorMessage = 'No s\'ha pogut carregar l\'estat del cim';
      notifyListeners();
    }
  }

  // Aquest mètode actualitza objectiu o preferit amb una estratègia optimista.
  // Primer actualitza el store i, si el backend falla, restaura l’estat anterior.
  Future<void> _updateStatus({
    bool? isTarget,
    bool? isFavorite,
  }) async {
    if (isUpdatingStatus || isLoading) {
      return;
    }

    final previousStatus = peakStatus;
    final baseStatus = previousStatus ?? PeakStatus.emptyForPeak(peakId);
    final optimisticStatus = baseStatus.copyWith(
      isTarget: isTarget,
      isFavorite: isFavorite,
    );

    isUpdatingStatus = true;
    statusErrorMessage = null;
    _peakStatusStore.setStatus(optimisticStatus);
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

      _restorePreviousStatus(previousStatus);
      statusErrorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      _restorePreviousStatus(previousStatus);
      statusErrorMessage = 'No s\'ha pogut actualitzar l\'estat del cim';
    } finally {
      if (!_disposed) {
        isUpdatingStatus = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode restaura el store al valor anterior al canvi optimista.
  void _restorePreviousStatus(PeakStatus? previousStatus) {
    if (previousStatus != null) {
      _peakStatusStore.setStatus(previousStatus);
    }
  }

  // Aquest mètode refresca la pantalla quan canvia el store d’estats.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // Aquest mètode tanca el controller i elimina el listener del store compartit.
  @override
  void dispose() {
    _disposed = true;
    _peakStatusStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
