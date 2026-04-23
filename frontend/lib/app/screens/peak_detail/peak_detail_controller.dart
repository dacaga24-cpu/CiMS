import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/usecase/get_peak_by_id_usecase.dart';
import 'package:flutter/material.dart';
import 'package:cims/core/client/api_client.dart';

// Aquest enum defineix les accions globals que la vista resoldrà des de fora.
// D’aquesta manera el controller no depèn de la navegació ni del context visual.
enum PeakDetailDestination {
  none,
  openMap,
  registerAscent,
}

// Aquest controller gestiona l’estat de la pantalla de detall del cim.
// Ara mateix carrega les dades del Peak i deixa preparades les accions futures.
class PeakDetailController extends ChangeNotifier {
  // Aquest constructor rep l’identificador del cim que s’ha de carregar
  // i prepara el cas d’ús responsable de recuperar-ne el detall.
  PeakDetailController({
    required this.peakId,
    GetPeakByIdUseCase? getPeakByIdUseCase,
  }) : _getPeakByIdUseCase = getPeakByIdUseCase ??
            GetPeakByIdUseCase(
              apiClient: ApiClientImpl(),
            );

  // Aquest bloc manté les dades principals que necessita el controller
  // per carregar el detall, guardar l’estat de la pantalla i comunicar accions a la vista.
  final int peakId;
  final GetPeakByIdUseCase _getPeakByIdUseCase;

  bool isLoading = false;
  String? errorMessage;
  Peak? peak;

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

  // Aquest bloc centralitza la càrrega real del cim.
  // Actualitza l’estat visual de la pantalla i transforma els possibles errors
  // en missatges que la vista pugui mostrar de manera clara.
  Future<void> _loadPeak() async {
    isLoading = true;
    errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final loadedPeak = await _getPeakByIdUseCase.execute(peakId);

      if (_disposed) {
        return;
      }

      peak = loadedPeak;
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}