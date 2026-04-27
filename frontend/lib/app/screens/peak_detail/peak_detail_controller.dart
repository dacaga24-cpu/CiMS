import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/usecase/get_ascents_by_peak_usecase.dart';
import 'package:cims/core/usecase/get_peak_by_id_usecase.dart';
import 'package:cims/core/usecase/get_peak_status_usecase.dart';
import 'package:cims/core/usecase/update_peak_status_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum defineix les accions globals que la vista resoldrà des de fora.
// D’aquesta manera el controller no depèn de la navegació ni del context visual.
enum PeakDetailDestination {
  none,
  openMap,
  registerAscent,
}

// Aquest controller gestiona l’estat de la pantalla de detall del cim.
// Carrega la informació principal del Peak, l’estat personal de l’usuari
// i les ascensions registrades per poder mostrar dades com l’últim ascens.
//
// Les accions sobre l'estat (objectiu, completat, preferit) apliquen un
// canvi optimista al store: la interfície es refresca immediatament i, si
// la petició al backend falla, el valor anterior es restaura.
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
    PeakStatusStore? peakStatusStore,
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
      peakStatusStore: peakStatusStore ?? AppSession.peakStatusStore,
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
    required PeakStatusStore peakStatusStore,
  })  : _getPeakByIdUseCase = getPeakByIdUseCase,
        _getPeakStatusUseCase = getPeakStatusUseCase,
        _updatePeakStatusUseCase = updatePeakStatusUseCase,
        _getAscentsByPeakUseCase = getAscentsByPeakUseCase,
        _peakStatusStore = peakStatusStore {
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
  final PeakStatusStore _peakStatusStore;

  // Aquest bloc representa l’estat visible de la pantalla.
  // La vista l’utilitza per mostrar càrregues, errors i dades del cim.
  bool isLoading = false;
  bool isUpdatingStatus = false;
  String? errorMessage;
  String? statusErrorMessage;
  String? ascentsErrorMessage;
  Peak? peak;
  DateTime? lastAscentDate;

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

  // Aquesta acció activa o desactiva el cim com a completat.
  // Aquest estat és independent del registre d’ascensió.
  Future<void> onCompletedTap() {
    final currentStatus = peakStatus ?? PeakStatus.emptyForPeak(peakId);

    return _updateStatus(
      isCompleted: !currentStatus.isCompleted,
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
    bool? isCompleted,
    bool? isTarget,
    bool? isFavorite,
  }) async {
    if (isUpdatingStatus || isLoading) {
      return;
    }

    final previousStatus = peakStatus;
    final baseStatus = previousStatus ?? PeakStatus.emptyForPeak(peakId);
    final optimisticStatus = baseStatus.copyWith(
      isCompleted: isCompleted,
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
        isCompleted: isCompleted,
        isTarget: isTarget,
        isFavorite: isFavorite,
      );

      if (_disposed) {
        return;
      }

      // La resposta del backend és la versió canònica i substitueix
      // l'estat optimista al store compartit.
      _peakStatusStore.setStatus(updatedStatus);
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