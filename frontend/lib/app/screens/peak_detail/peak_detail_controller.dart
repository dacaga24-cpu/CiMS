import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
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
// Carrega la informació principal del Peak i l’estat personal que l’usuari
// té assignat al cim.
class PeakDetailController extends ChangeNotifier {
  // Aquest constructor rep l’identificador del cim que s’ha de carregar
  // i prepara els casos d’ús responsables de recuperar-ne el detall,
  // consultar-ne l’estat personal i actualitzar-lo.
  factory PeakDetailController({
    required int peakId,
    ApiClient? apiClient,
    GetPeakByIdUseCase? getPeakByIdUseCase,
    GetPeakStatusUseCase? getPeakStatusUseCase,
    UpdatePeakStatusUseCase? updatePeakStatusUseCase,
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
    );
  }

  // Aquest constructor intern rep els casos d’ús ja preparats.
  // Ajuda a separar la creació de dependències de la lògica real del controller.
  PeakDetailController._({
    required this.peakId,
    required GetPeakByIdUseCase getPeakByIdUseCase,
    required GetPeakStatusUseCase getPeakStatusUseCase,
    required UpdatePeakStatusUseCase updatePeakStatusUseCase,
  })  : _getPeakByIdUseCase = getPeakByIdUseCase,
        _getPeakStatusUseCase = getPeakStatusUseCase,
        _updatePeakStatusUseCase = updatePeakStatusUseCase;

  // Aquest bloc manté les dades principals que necessita el controller
  // per carregar el detall, guardar l’estat de la pantalla i comunicar accions a la vista.
  final int peakId;
  final GetPeakByIdUseCase _getPeakByIdUseCase;
  final GetPeakStatusUseCase _getPeakStatusUseCase;
  final UpdatePeakStatusUseCase _updatePeakStatusUseCase;

  // Aquest bloc representa l’estat visible de la pantalla.
  // La vista l’utilitza per mostrar càrregues, errors, dades del cim i estat personal.
  bool isLoading = false;
  bool isUpdatingStatus = false;
  String? errorMessage;
  String? statusErrorMessage;
  Peak? peak;
  PeakStatus? peakStatus;

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

  // Aquesta acció deixa preparada la futura navegació
  // cap al registre d’una ascensió.
  void onRegisterAscentTap() {
    _destination = PeakDetailDestination.registerAscent;
    notifyListeners();
  }

  // Aquest mètode reinicia el destí un cop la vista ja l’ha consumit.
  void consumeNavigation() {
    _destination = PeakDetailDestination.none;
  }

  // Aquest bloc centralitza la càrrega real del cim i del seu estat personal.
  // Si l’estat encara no existeix al backend, es treballa amb un estat buit
  // perquè la pantalla pugui continuar funcionant amb normalitat.
  Future<void> _loadPeak() async {
    isLoading = true;
    errorMessage = null;
    statusErrorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final loadedPeak = await _getPeakByIdUseCase.execute(peakId);

      if (_disposed) {
        return;
      }

      peak = loadedPeak;
      peakStatus = await _loadPeakStatus();
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      peak = null;
      peakStatus = null;
      errorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      peak = null;
      peakStatus = null;
      errorMessage = 'No s\'ha pogut carregar el detall del cim';
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode carrega l’estat personal del cim.
  // Si hi ha un error específic d’estat, no bloqueja el detall del cim:
  // es mostra el cim i es deixa l’estat com a buit.
  Future<PeakStatus> _loadPeakStatus() async {
    try {
      final loadedStatus = await _getPeakStatusUseCase.execute(peakId);
      statusErrorMessage = null;
      return loadedStatus;
    } on ApiException catch (error) {
      statusErrorMessage = error.message;
      return PeakStatus.emptyForPeak(peakId);
    } catch (_) {
      statusErrorMessage = 'No s\'ha pogut carregar l\'estat del cim';
      return PeakStatus.emptyForPeak(peakId);
    }
  }

  // Aquest mètode actualitza l’estat personal del cim al backend
  // i guarda la resposta retornada per mantenir la pantalla sincronitzada.
  Future<void> _updateStatus({
    bool? isCompleted,
    bool? isTarget,
    bool? isFavorite,
  }) async {
    if (isUpdatingStatus || isLoading) {
      return;
    }

    isUpdatingStatus = true;
    statusErrorMessage = null;
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

      peakStatus = updatedStatus;
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      statusErrorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      statusErrorMessage = 'No s\'ha pogut actualitzar l\'estat del cim';
    } finally {
      if (!_disposed) {
        isUpdatingStatus = false;
        notifyListeners();
      }
    }
  }

  // Aquest mètode marca el controller com a tancat.
  // Així s’evita notificar canvis a una pantalla que ja no està activa.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}