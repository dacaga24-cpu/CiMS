import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/usecase/get_ascents_by_peak_usecase.dart';
import 'package:flutter/material.dart';

// Aquest controller gestiona l’estat de la pantalla d’historial d’ascensions.
// Carrega les ascensions associades al cim seleccionat i separa la lògica de dades
// de la composició visual de la pantalla.
class AscentHistoryController extends ChangeNotifier {
  AscentHistoryController({
    required this.peakId,
    GetAscentsByPeakUseCase? getAscentsByPeakUseCase,
  }) : _getAscentsByPeakUseCase =
            getAscentsByPeakUseCase ?? GetAscentsByPeakUseCase(ApiClientImpl());

  // Aquest identificador indica de quin cim s’ha de recuperar l’historial.
  // Arriba des de la pantalla d’estadístiques quan l’usuari selecciona una ascensió recent.
  final int peakId;

  // Aquest cas d’ús encapsula la consulta de les ascensions del cim.
  // El controller no fa peticions HTTP directes.
  final GetAscentsByPeakUseCase _getAscentsByPeakUseCase;

  // Aquest bloc conserva les dades i els estats visuals necessaris
  // per decidir si la pantalla mostra càrrega, error o llistat d’ascensions.
  List<Ascent> _ascents = const [];
  List<Ascent> get ascents => _ascents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;
  bool _hasLoaded = false;

  // Aquest getter indica si encara s’està fent la primera càrrega de dades.
  bool get isInitialLoading => _isLoading && _ascents.isEmpty;

  // Aquest mètode carrega l’historial només una vegada quan la pantalla s’obre.
  Future<void> initialize() async {
    if (_hasLoaded) return;

    _hasLoaded = true;
    await loadAscents();
  }

  // Aquest mètode recupera les ascensions del cim seleccionat i actualitza la pantalla.
  Future<void> loadAscents() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      _ascents = await _getAscentsByPeakUseCase.call(peakId);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No s\'han pogut carregar les ascensions del cim';
    } finally {
      _isLoading = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode permet refrescar manualment l’historial des de la pantalla.
  Future<void> onRefresh() {
    return loadAscents();
  }

  // Aquest mètode permet reintentar la càrrega quan hi ha hagut un error.
  Future<void> onRetryTap() {
    return loadAscents();
  }

  // Aquest mètode evita notificacions després que la pantalla s’hagi tancat.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}