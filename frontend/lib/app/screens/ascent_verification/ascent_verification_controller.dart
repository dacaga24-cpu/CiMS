import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/nearby_peak_candidate.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/ascents/create_verified_ascent_usecase.dart';
import 'package:cims/core/usecase/ascents/upload_ascent_photo_usecase.dart';
import 'package:cims/core/usecase/peaks/find_nearby_peaks_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// Aquest enum indica si la pantalla ha de navegar després de crear l’ascensió.
// Permet separar la decisió del controller de la navegació real de la pantalla.
enum AscentVerificationDestination {
  none,
  editAscent,
  back,
}

// Aquest enum identifica el tipus d’error que ha aturat el flux de verificació.
// La pantalla l’utilitza per oferir l’acció correcta (reintentar, obrir ajustos…).
enum AscentVerificationErrorKind {
  none,
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationTimeout,
  locationUnknown,
  cameraPermissionDenied,
  cameraCancelled,
  cameraFailed,
  submitFailed,
}

// Aquesta excepció interna porta el tipus d’error fins al catch del controller
// sense barrejar-se amb altres excepcions del sistema.
class _LocationCaptureFailure implements Exception {
  const _LocationCaptureFailure(this.kind);

  final AscentVerificationErrorKind kind;
}

// Aquest controller gestiona el flux de verificació ràpida.
// Primer captura ubicació i data, després proposa cims propers
// i finalment obre la càmera quan l’usuari ja ha triat el cim.
class AscentVerificationController extends ChangeNotifier {
  AscentVerificationController({
    ImagePicker? imagePicker,
    FindNearbyPeaksUseCase? findNearbyPeaksUseCase,
    UploadAscentPhotoUseCase? uploadAscentPhotoUseCase,
    CreateVerifiedAscentUseCase? createVerifiedAscentUseCase,
    PeakStatusStore? peakStatusStore,
    UserStatsRefreshStore? userStatsRefreshStore,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _findNearbyPeaksUseCase =
            findNearbyPeaksUseCase ?? FindNearbyPeaksUseCase(ApiClientImpl()),
        _uploadAscentPhotoUseCase =
            uploadAscentPhotoUseCase ?? UploadAscentPhotoUseCase(ApiClientImpl()),
        _createVerifiedAscentUseCase = createVerifiedAscentUseCase ??
            CreateVerifiedAscentUseCase(ApiClientImpl()),
        _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore;

  // Aquest temps màxim evita que la captura de GPS quedi penjada
  // quan el dispositiu no aconsegueix una posició fiable.
  static const Duration _locationTimeout = Duration(seconds: 20);

  final ImagePicker _imagePicker;
  final FindNearbyPeaksUseCase _findNearbyPeaksUseCase;
  final UploadAscentPhotoUseCase _uploadAscentPhotoUseCase;
  final CreateVerifiedAscentUseCase _createVerifiedAscentUseCase;

  // Aquests stores compartits permeten reflectir el canvi a la resta de pantalles.
  // Quan es crea una ascensió verificada, el cim passa a completat i verificat.
  final PeakStatusStore _peakStatusStore;
  final UserStatsRefreshStore _userStatsRefreshStore;

  bool _disposed = false;
  bool _isPreparingCapture = false;
  bool _isLoadingNearbyPeaks = false;
  String? _message;
  String? _errorMessage;
  AscentVerificationErrorKind _errorKind = AscentVerificationErrorKind.none;
  Position? _position;
  DateTime? _capturedAt;
  Uint8List? _photoBytes;
  String _photoMimeType = 'image/jpeg';
  List<NearbyPeakCandidate> _nearbyPeakCandidates = const [];
  NearbyPeakCandidate? _selectedNearbyPeakCandidate;
  Ascent? _createdAscent;
  AscentVerificationDestination _destination =
      AscentVerificationDestination.none;

  bool get isPreparingCapture => _isPreparingCapture;
  bool get isLoadingNearbyPeaks => _isLoadingNearbyPeaks;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  AscentVerificationErrorKind get errorKind => _errorKind;
  Position? get position => _position;
  DateTime? get capturedAt => _capturedAt;
  Uint8List? get photoBytes => _photoBytes;
  List<NearbyPeakCandidate> get nearbyPeakCandidates => _nearbyPeakCandidates;
  NearbyPeakCandidate? get selectedNearbyPeakCandidate =>
      _selectedNearbyPeakCandidate;
  Ascent? get createdAscent => _createdAscent;
  AscentVerificationDestination get destination => _destination;
  bool get hasLocation => _position != null;
  bool get hasEvidence => _position != null && _photoBytes != null;
  bool get hasSelectedPeak => _selectedNearbyPeakCandidate != null;

  // Aquest getter indica si l’error actual es resol obrint la configuració del sistema
  // (servei d’ubicació desactivat). La pantalla l’utilitza per mostrar el botó adient.
  bool get errorNeedsLocationSettings =>
      _errorKind == AscentVerificationErrorKind.locationServiceDisabled;

  // Aquest getter indica si l’error actual es resol obrint la configuració de l’app
  // (permís denegat per sempre o denegat per la càmera).
  bool get errorNeedsAppSettings =>
      _errorKind == AscentVerificationErrorKind.locationPermissionDeniedForever ||
      _errorKind == AscentVerificationErrorKind.cameraPermissionDenied;

  // Aquest mètode neteja la navegació pendent després que la pantalla l’hagi consumit.
  // Evita repetir la mateixa navegació en futures notificacions del controller.
  void consumeNavigation() {
    _destination = AscentVerificationDestination.none;
  }

  // Aquest mètode inicia la verificació capturant ubicació i data.
  // Després carrega els cims propers perquè l’usuari triï el cim abans de fer la foto.
  Future<void> prepareCapture() async {
    if (_isPreparingCapture) {
      return;
    }

    _isPreparingCapture = true;
    _isLoadingNearbyPeaks = false;
    _message = 'Capturant la ubicació actual...';
    _errorMessage = null;
    _errorKind = AscentVerificationErrorKind.none;
    _position = null;
    _capturedAt = null;
    _photoBytes = null;
    _photoMimeType = 'image/jpeg';
    _nearbyPeakCandidates = const [];
    _selectedNearbyPeakCandidate = null;
    _createdAscent = null;
    _destination = AscentVerificationDestination.none;
    _safeNotifyListeners();

    try {
      _position = await _captureCurrentLocation();
      _capturedAt = DateTime.now();
      _message = 'Ubicació capturada. Selecciona quin cim vols verificar.';
      _safeNotifyListeners();

      await _loadNearbyPeaks();
    } on _LocationCaptureFailure catch (failure) {
      _applyLocationFailure(failure.kind);
    } catch (error) {
      debugPrint('[AscentVerificationController] Location error: $error');
      _applyLocationFailure(AscentVerificationErrorKind.locationUnknown);
    } finally {
      _isPreparingCapture = false;
      _isLoadingNearbyPeaks = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode selecciona el cim que l’usuari vol verificar.
  // El backend rebrà aquest cim juntament amb la foto i la ubicació capturada.
  void selectNearbyPeakCandidate(NearbyPeakCandidate candidate) {
    _selectedNearbyPeakCandidate = candidate;
    _message = 'Cim seleccionat: ${candidate.peak.name}.';
    _errorMessage = null;
    _errorKind = AscentVerificationErrorKind.none;
    _safeNotifyListeners();
  }

  void capturePhoto() {
    _capturePhoto();
  }

  void createVerifiedAscent() {
    _submitVerifiedAscent(completeNow: true);
  }

  void completeLater() {
    _submitVerifiedAscent(completeNow: false);
  }

  Future<void> retryCapture() async {
    await prepareCapture();
  }

  // Aquest mètode obre la configuració del sistema per activar el servei d’ubicació.
  // Es fa servir quan la captura ha fallat perquè el GPS estava desactivat.
  Future<void> openLocationSystemSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Aquest mètode obre la pantalla de permisos de l’app dins de la configuració.
  // Permet recuperar permisos denegats per sempre per a càmera o ubicació.
  Future<void> openAppSystemSettings() async {
    await Geolocator.openAppSettings();
  }

  // Aquest mètode obre la càmera quan ja hi ha un cim seleccionat.
  // La foto capturada serà l’evidència visual associada a l’ascensió verificada.
  Future<void> _capturePhoto() async {
    if (_isPreparingCapture) {
      return;
    }

    if (_position == null || _capturedAt == null) {
      _errorMessage =
          'Cal capturar la ubicació abans de fer la foto de verificació.';
      _errorKind = AscentVerificationErrorKind.locationUnknown;
      _safeNotifyListeners();
      return;
    }

    if (_selectedNearbyPeakCandidate == null) {
      _errorMessage = 'Selecciona quin cim vols verificar abans de fer la foto.';
      _errorKind = AscentVerificationErrorKind.none;
      _safeNotifyListeners();
      return;
    }

    _isPreparingCapture = true;
    _errorMessage = null;
    _errorKind = AscentVerificationErrorKind.none;
    _message = 'Obrint la càmera...';
    _safeNotifyListeners();

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );

      if (pickedImage == null) {
        _errorMessage =
            'No s\'ha fet cap foto de verificació. Torna a obrir la càmera per intentar-ho.';
        _errorKind = AscentVerificationErrorKind.cameraCancelled;
        return;
      }

      _photoMimeType = pickedImage.mimeType ?? 'image/jpeg';
      _photoBytes = await pickedImage.readAsBytes();
      _message = 'Foto capturada correctament.';
    } catch (error) {
      debugPrint('[AscentVerificationController] Photo error: $error');
      final isPermissionError = error.toString().toLowerCase().contains(
            'permission',
          );
      _errorKind = isPermissionError
          ? AscentVerificationErrorKind.cameraPermissionDenied
          : AscentVerificationErrorKind.cameraFailed;
      _errorMessage = isPermissionError
          ? 'No s\'ha pogut accedir a la càmera. Concedeix el permís de càmera des de la configuració de l\'app.'
          : 'No s\'ha pogut fer la foto de verificació. Torna-ho a provar.';
    } finally {
      _isPreparingCapture = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode puja la foto i crea l’ascensió verificada al backend.
  // Serveix tant per completar-la al moment com per deixar-la creada i editar-la més endavant.
  Future<void> _submitVerifiedAscent({
    required bool completeNow,
  }) async {
    final currentPosition = _position;
    final currentCapturedAt = _capturedAt;
    final currentPhotoBytes = _photoBytes;
    final selectedCandidate = _selectedNearbyPeakCandidate;

    if (currentPosition == null ||
        currentCapturedAt == null ||
        currentPhotoBytes == null) {
      _errorMessage =
          'Cal capturar una foto i la ubicació abans de crear l\'ascensió verificada.';
      _errorKind = AscentVerificationErrorKind.none;
      _safeNotifyListeners();
      return;
    }

    if (selectedCandidate == null) {
      _errorMessage = 'Selecciona quin cim vols verificar.';
      _errorKind = AscentVerificationErrorKind.none;
      _safeNotifyListeners();
      return;
    }

    _isPreparingCapture = true;
    _errorMessage = null;
    _errorKind = AscentVerificationErrorKind.none;
    _destination = AscentVerificationDestination.none;
    _message = completeNow
        ? 'Creant l\'ascensió verificada...'
        : 'Guardant l\'ascensió per completar-la més endavant...';
    _safeNotifyListeners();

    try {
      final uploadedPhoto = await _uploadAscentPhotoUseCase(
        bytes: currentPhotoBytes,
        mimeType: _photoMimeType,
        isPrimary: true,
        isVerificationEvidence: true,
      );

      final ascent = await _createVerifiedAscentUseCase(
        peakId: selectedCandidate.peak.id,
        notes: null,
        photos: [uploadedPhoto],
        capturedLatitude: currentPosition.latitude,
        capturedLongitude: currentPosition.longitude,
        capturedAccuracyMeters: currentPosition.accuracy,
        capturedAt: currentCapturedAt,
      );

      _createdAscent = ascent;
      _syncVerifiedAscentSideEffects(selectedCandidate.peak.id);

      _message = completeNow
          ? 'Ascensió verificada creada. Ja pots completar-ne les dades.'
          : 'Ascensió verificada creada. La podràs completar més endavant des de l’historial.';
      _destination = completeNow
          ? AscentVerificationDestination.editAscent
          : AscentVerificationDestination.back;
    } catch (error) {
      debugPrint('[AscentVerificationController] Submit error: $error');
      _errorKind = AscentVerificationErrorKind.submitFailed;
      _errorMessage =
          'No s\'ha pogut crear l\'ascensió verificada. Revisa la connexió i torna-ho a provar.';
    } finally {
      _isPreparingCapture = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode actualitza l’estat compartit després de crear una ascensió verificada.
  // Així el catàleg, el mapa, el detall, el dashboard i les estadístiques poden refrescar-se.
  void _syncVerifiedAscentSideEffects(int peakId) {
    _peakStatusStore.markCompletedAndVerified(peakId);
    _userStatsRefreshStore.notifyStatsChanged();
  }

  // Aquest mètode carrega els cims propers a la ubicació capturada.
  // Permet proposar opcions reals abans de fer la foto de verificació.
  Future<void> _loadNearbyPeaks() async {
    final currentPosition = _position;

    if (currentPosition == null) {
      return;
    }

    _isLoadingNearbyPeaks = true;
    _safeNotifyListeners();

    try {
      final candidates = await _findNearbyPeaksUseCase(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        limit: 3,
      );

      _nearbyPeakCandidates = candidates;
      _selectedNearbyPeakCandidate =
          candidates.isNotEmpty ? candidates.first : null;

      if (candidates.isEmpty) {
        _errorMessage = 'No s\'ha trobat cap cim proper per verificar.';
        _errorKind = AscentVerificationErrorKind.none;
      }
    } catch (error) {
      debugPrint('[AscentVerificationController] Nearby peaks error: $error');
      _errorMessage = 'No s\'han pogut carregar els cims propers.';
      _errorKind = AscentVerificationErrorKind.none;
    } finally {
      _isLoadingNearbyPeaks = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode comprova permisos i obté la posició actual del dispositiu.
  // Llença excepcions tipades perquè la pantalla pugui oferir la millor acció.
  Future<Position> _captureCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const _LocationCaptureFailure(
        AscentVerificationErrorKind.locationServiceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _LocationCaptureFailure(
        AscentVerificationErrorKind.locationPermissionDeniedForever,
      );
    }

    if (permission == LocationPermission.denied) {
      throw const _LocationCaptureFailure(
        AscentVerificationErrorKind.locationPermissionDenied,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      );
    } on TimeoutException {
      throw const _LocationCaptureFailure(
        AscentVerificationErrorKind.locationTimeout,
      );
    }
  }

  // Aquest mètode tradueix el tipus d’error d’ubicació en un missatge clar
  // i marca el tipus perquè la pantalla mostri l’acció més útil.
  void _applyLocationFailure(AscentVerificationErrorKind kind) {
    _errorKind = kind;
    switch (kind) {
      case AscentVerificationErrorKind.locationServiceDisabled:
        _errorMessage =
            'El servei d\'ubicació està desactivat. Activa\'l per verificar el cim.';
        break;
      case AscentVerificationErrorKind.locationPermissionDenied:
        _errorMessage =
            'Cal el permís d\'ubicació per verificar el cim. Torna-ho a intentar i concedeix el permís.';
        break;
      case AscentVerificationErrorKind.locationPermissionDeniedForever:
        _errorMessage =
            'El permís d\'ubicació està bloquejat. Obre la configuració de l\'app per activar-lo.';
        break;
      case AscentVerificationErrorKind.locationTimeout:
        _errorMessage =
            'No s\'ha pogut obtenir la ubicació a temps. Comprova la cobertura GPS i torna-ho a provar.';
        break;
      default:
        _errorMessage =
            'No s\'ha pogut preparar la verificació. Torna-ho a provar.';
        break;
    }
  }

  // Aquest mètode centralitza la notificació de canvis
  // i evita intentar actualitzar la vista quan el controller ja s’ha tancat.
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
