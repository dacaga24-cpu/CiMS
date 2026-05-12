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

// Aquest enum defineix les accions globals que la vista resoldrà des de fora.
// D’aquesta manera el controller no depèn de la navegació ni del context visual.
enum PeakDetailDestination {
  none,
  openMap,
  registerAscent,
  ascentHistory,
}

// Les accions manuals sobre l'estat només permeten modificar objectiu i preferit.
// L'estat completat es deriva de les ascensions registrades i es mostra com a segell.
class PeakDetailController extends ChangeNotifier {
  // Aquest constructor rep l’identificador del cim que s’ha de carregar
  // i prepara els casos d’ús responsables de recuperar-ne el detall,
  // consultar-ne l’estat personal, actualitzar-lo i llegir les ascensions.
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

  // Aquest constructor intern rep els casos d’ús ja preparats.
  // Ajuda a separar la creació de dependències de la lògica real del controller.
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
    // El controller s'enganxa al store per propagar els canvis fets per
    // qualsevol altra pantalla a la vista del detall.
    _peakStatusStore.addListener(_onStoreChanged);
  }

  // Aquest bloc manté les dades principals que necessita el controller
  // per carregar el detall, guardar l’estat de la pantalla i comunicar accions a la vista.
  final int peakId;
  final GetPeakByIdUseCase _getPeakByIdUseCase;
  final GetPeakStatusUseCase _getPeakStatusUseCase;
  final UpdatePeakStatusUseCase _updatePeakStatusUseCase;
  final GetAscentsByPeakUseCase _getAscentsByPeakUseCase;
  final GetPeakDailyWeatherUseCase _getPeakDailyWeatherUseCase;
  final GetPeakHourlyWeatherUseCase _getPeakHourlyWeatherUseCase;
  final PeakStatusStore _peakStatusStore;

  // Aquest store avisa altres pantalles que les dades de progrés poden haver canviat.
  // Permet que el dashboard i les estadístiques es refresquin després de modificar un estat.
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquest bloc representa l’estat visible de la pantalla.
  // La vista l’utilitza per mostrar càrregues, errors i dades del cim.
  bool isLoading = false;
  bool isUpdatingStatus = false;
  String? errorMessage;
  String? statusErrorMessage;
  String? ascentsErrorMessage;
  Peak? peak;
  DateTime? lastAscentDate;

  // Aquest bloc guarda l'estat de la previsió meteorològica. Es manté
  // separat de la càrrega general del cim perquè una fallada del
  // proveïdor (Google fora de servei, quota esgotada) no ha d'impedir
  // veure la resta del detall: la card mostrarà l'error i la pantalla
  // seguirà funcionant amb normalitat.
  bool isWeatherLoading = false;
  String? weatherErrorMessage;
  PeakWeather? weatherForecast;

  // El comptador de càrregues serveix per descartar respostes
  // obsoletes: si l'usuari fa pull-to-refresh dues vegades seguides o
  // toca "Reintenta" mentre encara hi ha un fetch en vol, només la més
  // recent pot escriure a l'estat. Sense aquest guard, un primer fetch
  // que falla tard pot pisar el resultat correcte d'un fetch posterior.
  int _weatherLoadId = 0;

  // Aquest bloc manté l'estat del panell horari que es desplega quan
  // l'usuari toca una píldora del carrusel diari. Es modela com un
  // diccionari per data perquè diferents dies tinguin cache, estat de
  // càrrega i error independents: així, si l'usuari obre dimecres,
  // toca Dijous i torna a Dimecres, la previsió de dimecres encara hi
  // és sense haver de tornar a demanar-la a Google.
  final Map<String, PeakHourlyWeather> _hourlyByDay = {};
  final Set<String> _hourlyLoadingDays = {};
  final Map<String, String> _hourlyErrorByDay = {};

  // El comptador per dia serveix per resoldre races dins d'un mateix
  // dia (per exemple, expandir, col·lapsar i tornar a expandir abans
  // que torni la primera resposta). Una crida obsoleta es descarta
  // comparant el seu loadId amb el guardat aquí.
  final Map<String, int> _hourlyLoadIdByDay = {};

  // Aquesta propietat manté la data del dia actualment expandit (o null
  // si cap dia ho està). El widget l'utilitza per pintar la píldora amb
  // un estat d'accent diferent i decidir quin panell horari mostrar.
  String? _expandedDay;
  String? get expandedDay => _expandedDay;

  // Vistes immutables del cache horari perquè la UI les pugui consultar
  // sense risc de modificar-les directament des del widget.
  PeakHourlyWeather? hourlyForDay(String date) => _hourlyByDay[date];
  bool isHourlyLoading(String date) => _hourlyLoadingDays.contains(date);
  String? hourlyErrorFor(String date) => _hourlyErrorByDay[date];

  // L'estat personal del cim no es guarda aquí: es llegeix sempre del store
  // compartit per garantir que cap còpia local el desincronitzi.
  PeakStatus? get peakStatus => _peakStatusStore.getStatus(peakId);

  // Aquest bloc controla l’estat intern del controller.
  // Evita actualitzar la pantalla quan ja s’ha tancat i guarda la navegació pendent.
  bool _disposed = false;
  PeakDetailDestination _destination = PeakDetailDestination.none;

  PeakDetailDestination get destination => _destination;

  // Aquest mètode prepara la càrrega inicial del detall del cim.
  Future<void> initialize() {
    return _loadPeak();
  }

  // Aquest mètode permet reintentar la càrrega quan hi ha un error.
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

  // Aquesta acció deixa preparada la futura obertura del mapa.
  void onMapTap() {
    _destination = PeakDetailDestination.openMap;
    notifyListeners();
  }

  // Aquesta acció deixa preparada la navegació cap al registre d’una ascensió.
  void onRegisterAscentTap() {
    _destination = PeakDetailDestination.registerAscent;
    notifyListeners();
  }

  // Aquesta acció deixa preparada la navegació cap a l’historial d’ascensions del cim.
  void onAscentHistoryTap() {
    _destination = PeakDetailDestination.ascentHistory;
    notifyListeners();
  }

  // Aquest mètode reinicia el destí un cop la vista ja l’ha consumit.
  void consumeNavigation() {
    _destination = PeakDetailDestination.none;
  }

  // Aquest mètode recupera les ascensions personals de l’usuari sobre aquest cim.
  // La data més recent es guarda per mostrar-la a la capçalera del detall.
  Future<void> refreshLastAscentDate() async {
    try {
      final ascents = await _getAscentsByPeakUseCase(peakId);

      if (_disposed) {
        return;
      }

      lastAscentDate = ascents.isEmpty ? null : ascents.first.ascentDate;
      ascentsErrorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      ascentsErrorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      ascentsErrorMessage = 'No s\'han pogut carregar les ascensions del cim';
    }
  }

  // Aquest bloc centralitza la càrrega real del cim, del seu estat personal
  // i de l’última ascensió registrada per l’usuari.
  Future<void> _loadPeak() async {
    isLoading = true;
    errorMessage = null;
    statusErrorMessage = null;
    ascentsErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    // La previsió meteorològica es dispara en paral·lel a la càrrega del
    // cim perquè només depèn del peakId, que ja tenim. Així la card del
    // clima pot començar a omplir-se mentre encara estem demanant les
    // dades bàsiques del cim, i una fallada de Google no bloqueja la
    // resta del detall. El Future no s'espera aquí: _loadWeather manté
    // el seu propi estat (isWeatherLoading, weatherErrorMessage) i avisa
    // els listeners quan acaba.
    unawaited(_loadWeather());

    try {
      final loadedPeak = await _getPeakByIdUseCase.execute(peakId);

      if (_disposed) {
        return;
      }

      peak = loadedPeak;
      await _refreshPeakStatusFromBackend();
      await refreshLastAscentDate();
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      peak = null;
      errorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      peak = null;
      errorMessage = 'No s\'ha pogut carregar el detall del cim';
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode carrega la previsió meteorològica del cim. Una fallada
  // aquí no propaga errorMessage perquè la resta de la pantalla ha de
  // continuar funcionant: el clima és un complement, no la informació
  // essencial. Si Google no respon o la quota s'esgota, la card del clima
  // mostrarà el seu propi missatge d'error amb un botó de reintentar.
  //
  // Cada invocació rep un loadId propi: si quan torna la resposta ja
  // s'ha disparat una crida més recent, descartem el resultat per evitar
  // que un fetch antic pisi un de més nou. El mateix guard al finally
  // assegura que isWeatherLoading només es desactivi quan acaba la
  // crida més recent, mantenint l'esquelet visible si encara n'hi ha
  // una altra en vol.
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

      // Es loguen runtimeType i stack perquè un error no controlat aquí
      // (per exemple, un canvi de contracte del backend que faci petar
      // PeakWeather.fromJson) quedi rastrejable als logs del dispositiu
      // en lloc de quedar amagat darrere del missatge genèric.
      debugPrint(
        '[weather] load failed: ${error.runtimeType} — $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      weatherForecast = null;
      weatherErrorMessage =
          'No s\'ha pogut carregar la previsió meteorològica';
    } finally {
      if (!_disposed && loadId == _weatherLoadId) {
        isWeatherLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode permet reintentar només la càrrega de la previsió
  // meteorològica quan ha fallat, sense haver de tornar a carregar tot
  // el detall del cim. La card l'utilitza des del botó de reintentar.
  Future<void> onWeatherRetryTap() {
    return _loadWeather();
  }

  // Aquest mètode gestiona el desplegament del panell horari per a un
  // dia concret. Es comporta com a toggle: si la data rebuda ja és la
  // que està expandida, es col·lapsa; en cas contrari, s'expandeix la
  // nova i la càrrega es dispara només si encara no tenim les hores
  // d'aquest dia cachejades. Així una segona obertura del mateix dia
  // és instantània i no torna a tocar la xarxa.
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

  // Aquest mètode permet reintentar la càrrega horària per a un dia
  // concret quan ha fallat. La card del clima l'utilitza des del botó
  // "Reintenta" del panell horari, sense afectar la previsió diària.
  Future<void> onHourlyRetryTap(String date) {
    return _loadHourlyFor(date);
  }

  // Aquest mètode carrega la previsió horària per a una data concreta.
  // Manté un comptador per data per descartar respostes obsoletes
  // (l'usuari pot col·lapsar i tornar a expandir abans que torni la
  // primera resposta). Una fallada queda guardada al diccionari d'error
  // perquè el panell pugui mostrar-la sense barrejar-se amb errors
  // d'altres dies.
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

      _hourlyErrorByDay[date] =
          'No s\'ha pogut carregar la previsió horària';
    } finally {
      if (!_disposed && _hourlyLoadIdByDay[date] == loadId) {
        _hourlyLoadingDays.remove(date);
        notifyListeners();
      }
    }
  }

  // Aquest mètode demana al backend l'estat personal del cim i el bolca al
  // store. Si la petició falla, no es trenca la pantalla: es deixa el que ja
  // hi havia al store i es guarda un missatge d'error específic d'estat.
  Future<void> _refreshPeakStatusFromBackend() async {
    try {
      final loadedStatus = await _getPeakStatusUseCase.execute(peakId);
      statusErrorMessage = null;

      if (_disposed) {
        return;
      }

      _peakStatusStore.setStatus(loadedStatus);
    } on ApiException catch (error) {
      statusErrorMessage = error.message;
    } catch (_) {
      statusErrorMessage = 'No s\'ha pogut carregar l\'estat del cim';
    }
  }

  // Aquest mètode actualitza l’estat personal del cim al backend amb una
  // estratègia optimista: primer s'aplica el canvi al store perquè la UI
  // respongui a l'instant, i només si el backend rebutja la petició es
  // restaura el valor anterior.
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

      // La resposta del backend és la versió canònica i substitueix
      // l'estat optimista al store compartit.
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

  // Aquest mètode reverteix el store al valor que tenia abans del canvi optimista.
  // Si abans no hi havia cap registre, no força cap estat nou.
  void _restorePreviousStatus(PeakStatus? previousStatus) {
    if (previousStatus != null) {
      _peakStatusStore.setStatus(previousStatus);
    }
  }

  // Quan el store canvia per qualsevol motiu, la pantalla es refresca
  // perquè els indicadors d'estat reflecteixin el valor nou.
  void _onStoreChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // Aquest mètode marca el controller com a tancat.
  // Així s’evita notificar canvis a una pantalla que ja no està activa.
  @override
  void dispose() {
    _disposed = true;
    _peakStatusStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
