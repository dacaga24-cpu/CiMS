import 'dart:async';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/nearby_peak_candidate.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/ascents/create_verified_ascent_usecase.dart';
import 'package:cims/core/usecase/ascents/upload_ascent_photo_usecase.dart';
import 'package:cims/core/usecase/peaks/find_nearby_peaks_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// Aquest enum indica la navegació pendent després de crear una ascensió verificada.
// La pantalla resol l’acció sense barrejar navegació i lògica del controller.
enum AscentVerificationDestination {
  none,
  editAscent,
  back,
}

// Aquest enum identifica el tipus d’error que ha aturat el flux de verificació.
// Permet que la pantalla mostri el missatge i l’acció més adequada.
enum AscentVerificationErrorKind {
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationTimeout,
  locationUnknown,
  cameraPermissionDenied,
  cameraCancelled,
  cameraFailed,
  submitNetwork,
  submitRejected,
  submitSessionExpired,
  submitUnknown,
}

// Aquesta excepció interna transporta el tipus d’error d’ubicació.
// Permet tractar el flux de captura amb missatges específics.
class _LocationCaptureFailure implements Exception {
  const _LocationCaptureFailure(this.kind);

  final AscentVerificationErrorKind kind;
}

// Aquesta classe agrupa el tipus i el missatge d’un error d’enviament.
// Facilita mostrar textos clars sense exposar detalls tècnics del backend.
class _SubmitErrorTranslation {
  const _SubmitErrorTranslation(this.kind, this.message);

  final AscentVerificationErrorKind kind;
  final String message;
}

// Aquest controller gestiona el flux de verificació ràpida d’una ascensió.
// Captura ubicació, proposa cims propers, gestiona la foto i crea el registre verificat.
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
        _uploadAscentPhotoUseCase = uploadAscentPhotoUseCase ??
            UploadAscentPhotoUseCase(ApiClientImpl()),
        _createVerifiedAscentUseCase = createVerifiedAscentUseCase ??
            CreateVerifiedAscentUseCase(ApiClientImpl()),
        _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore;

  // Aquest temps màxim evita que la captura d’ubicació quedi bloquejada.
  static const Duration _locationTimeout = Duration(seconds: 20);

  // Aquesta configuració redueix el pes de la foto abans de pujar-la.
  // Manté qualitat suficient per usar-la com a evidència dins de l’aplicació.
  static const int _minPhotoWidth = 1920;
  static const int _minPhotoHeight = 1920;
  static const int _photoJpegQuality = 82;
  static const String _photoMimeTypeAfterCompression = 'image/jpeg';

  final ImagePicker _imagePicker;
  final FindNearbyPeaksUseCase _findNearbyPeaksUseCase;
  final UploadAscentPhotoUseCase _uploadAscentPhotoUseCase;
  final CreateVerifiedAscentUseCase _createVerifiedAscentUseCase;

  // Aquests stores permeten reflectir el canvi a la resta de pantalles.
  // Quan es crea una ascensió verificada, el cim queda completat i verificat.
  final PeakStatusStore _peakStatusStore;
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquestes dades mantenen l’estat intern del flux de verificació.
  // Inclouen càrrega, missatges, error actiu, ubicació, foto, cim seleccionat i navegació.
  bool _disposed = false;
  bool _isPreparingCapture = false;
  bool _isLoadingNearbyPeaks = false;
  String? _message;
  String? _errorMessage;
  AscentVerificationErrorKind? _errorKind;
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
  AscentVerificationErrorKind? get errorKind => _errorKind;
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

  // Aquest getter indica si l’error es pot resoldre obrint la configuració d’ubicació.
  // A web no s’ofereix perquè els permisos es gestionen des del navegador.
  bool get errorNeedsLocationSettings =>
      !kIsWeb &&
      _errorKind == AscentVerificationErrorKind.locationServiceDisabled;

  // Aquest getter indica si l’error es pot resoldre obrint la configuració de l’app.
  // S’utilitza per permisos bloquejats de càmera o ubicació en dispositius natius.
  bool get errorNeedsAppSettings =>
      !kIsWeb &&
      (_errorKind ==
              AscentVerificationErrorKind.locationPermissionDeniedForever ||
          _errorKind == AscentVerificationErrorKind.cameraPermissionDenied);

  // Aquest mètode neteja la navegació pendent després que la pantalla l’hagi resolt.
  void consumeNavigation() {
    _destination = AscentVerificationDestination.none;
  }

  // Aquest mètode actualitza el tipus i el missatge d’error alhora.
  // Manté l’estat d’error coherent per a la pantalla.
  void _setError({
    required AscentVerificationErrorKind? kind,
    required String? message,
  }) {
    _errorKind = kind;
    _errorMessage = message;
  }

  void _clearError() {
    _setError(kind: null, message: null);
  }

  // Aquest mètode inicia el flux capturant ubicació i data.
  // Després carrega els cims propers perquè l’usuari seleccioni quin vol verificar.
  Future<void> prepareCapture() async {
    if (_isPreparingCapture) {
      return;
    }

    _isPreparingCapture = true;
    _isLoadingNearbyPeaks = false;
    _message = 'Capturant la ubicació actual...';
    _clearError();
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
  // El cim triat s’enviarà al backend amb la foto i la ubicació capturada.
  void selectNearbyPeakCandidate(NearbyPeakCandidate candidate) {
    _selectedNearbyPeakCandidate = candidate;
    _message = 'Cim seleccionat: ${candidate.peak.name}.';
    _clearError();
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

  // Aquest mètode obre la configuració del sistema per activar la ubicació.
  Future<void> openLocationSystemSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Aquest mètode obre la configuració de permisos de l’aplicació.
  Future<void> openAppSystemSettings() async {
    await Geolocator.openAppSettings();
  }

  // Aquest mètode obre la càmera quan ja hi ha ubicació i cim seleccionat.
  // La foto capturada serà l’evidència visual de l’ascensió verificada.
  Future<void> _capturePhoto() async {
    if (_isPreparingCapture) {
      return;
    }

    if (_position == null || _capturedAt == null) {
      _setError(
        kind: AscentVerificationErrorKind.locationUnknown,
        message:
            'Cal capturar la ubicació abans de fer la foto de verificació.',
      );
      _safeNotifyListeners();
      return;
    }

    if (_selectedNearbyPeakCandidate == null) {
      _setError(
        kind: null,
        message: 'Selecciona quin cim vols verificar abans de fer la foto.',
      );
      _safeNotifyListeners();
      return;
    }

    _isPreparingCapture = true;
    _clearError();
    _message = 'Obrint la càmera...';
    _safeNotifyListeners();

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );

      if (pickedImage == null) {
        _setError(
          kind: AscentVerificationErrorKind.cameraCancelled,
          message:
              'No s\'ha fet cap foto de verificació. Torna a obrir la càmera per intentar-ho.',
        );
        return;
      }

      final originalBytes = await pickedImage.readAsBytes();

      // Aquesta compressió prepara la foto abans de pujar-la.
      // Redueix el pes de la imatge sense perdre la funció d’evidència visual.
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: _minPhotoWidth,
        minHeight: _minPhotoHeight,
        quality: _photoJpegQuality,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes.isEmpty) {
        debugPrint(
          '[AscentVerificationController] Photo compression returned empty bytes',
        );
        _photoBytes = null;
        _setError(
          kind: AscentVerificationErrorKind.cameraFailed,
          message:
              'No s\'ha pogut processar la foto. Prova a fer-ne una altra.',
        );
        return;
      }

      _photoBytes = compressedBytes;
      _photoMimeType = _photoMimeTypeAfterCompression;
      _message = 'Foto capturada correctament.';
    } catch (error, stack) {
      debugPrint(
        '[AscentVerificationController] Photo error (${error.runtimeType}): $error\n$stack',
      );
      final isPermissionError = error.toString().toLowerCase().contains(
            'permission',
          );
      _setError(
        kind: isPermissionError
            ? AscentVerificationErrorKind.cameraPermissionDenied
            : AscentVerificationErrorKind.cameraFailed,
        message: isPermissionError
            ? kIsWeb
                ? 'No s\'ha pogut accedir a la càmera. Revisa el permís de càmera del navegador per a aquest lloc.'
                : 'No s\'ha pogut accedir a la càmera. Concedeix el permís de càmera des de la configuració de l\'app.'
            : 'No s\'ha pogut fer la foto de verificació. Torna-ho a provar.',
      );
    } finally {
      _isPreparingCapture = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode puja la foto i crea l’ascensió verificada al backend.
  // Serveix tant per completar-la al moment com per deixar-la per editar més endavant.
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
      _setError(
        kind: null,
        message:
            'Cal capturar una foto i la ubicació abans de crear l\'ascensió verificada.',
      );
      _safeNotifyListeners();
      return;
    }

    if (selectedCandidate == null) {
      _setError(
        kind: null,
        message: 'Selecciona quin cim vols verificar.',
      );
      _safeNotifyListeners();
      return;
    }

    _isPreparingCapture = true;
    _clearError();
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
    } on ApiException catch (error) {
      debugPrint(
        '[AscentVerificationController] Submit ApiException '
        '(status=${error.statusCode}): ${error.message}',
      );
      final translated = _translateSubmitError(error);
      _setError(kind: translated.kind, message: translated.message);
    } catch (error, stack) {
      debugPrint(
        '[AscentVerificationController] Submit error '
        '(${error.runtimeType}): $error\n$stack',
      );
      _setError(
        kind: AscentVerificationErrorKind.submitUnknown,
        message:
            'No s\'ha pogut crear l\'ascensió verificada. Revisa la connexió i torna-ho a provar.',
      );
    } finally {
      _isPreparingCapture = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode actualitza l’estat compartit després de crear una ascensió verificada.
  // Permet refrescar catàleg, mapa, detall, dashboard i estadístiques.
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
        _setError(
          kind: null,
          message: 'No s\'ha trobat cap cim proper per verificar.',
        );
      }
    } catch (error, stack) {
      debugPrint(
        '[AscentVerificationController] Nearby peaks error '
        '(${error.runtimeType}): $error\n$stack',
      );
      _setError(
        kind: null,
        message: 'No s\'han pogut carregar els cims propers.',
      );
    } finally {
      _isLoadingNearbyPeaks = false;
      _safeNotifyListeners();
    }
  }

  // Aquest mètode obté la posició actual del dispositiu.
  // En web, el navegador gestiona directament el permís d’ubicació.
  Future<Position> _captureCurrentLocation() async {
    if (kIsWeb) {
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

  // Aquest mètode tradueix errors d’ubicació en missatges clars.
  // També marca el tipus perquè la pantalla pugui oferir l’acció adequada.
  void _applyLocationFailure(AscentVerificationErrorKind kind) {
    final String message;
    switch (kind) {
      case AscentVerificationErrorKind.locationServiceDisabled:
        message = kIsWeb
            ? 'El navegador no pot obtenir la ubicació. Comprova que tinguis el GPS o WiFi actiu i torna-ho a provar.'
            : 'El servei d\'ubicació està desactivat. Activa\'l per verificar el cim.';
        break;
      case AscentVerificationErrorKind.locationPermissionDenied:
        message =
            'Cal el permís d\'ubicació per verificar el cim. Torna-ho a intentar i concedeix el permís.';
        break;
      case AscentVerificationErrorKind.locationPermissionDeniedForever:
        message = kIsWeb
            ? 'El navegador ha bloquejat la ubicació per a aquest lloc. Obre la configuració del lloc al navegador (icona del cadenat a la barra d\'adreces) i permet la ubicació.'
            : 'El permís d\'ubicació està bloquejat. Obre la configuració de l\'app per activar-lo.';
        break;
      case AscentVerificationErrorKind.locationTimeout:
        message =
            'No s\'ha pogut obtenir la ubicació a temps. Comprova la cobertura GPS i torna-ho a provar.';
        break;
      default:
        message =
            'No s\'ha pogut preparar la verificació. Revisa el permís d’ubicació i torna-ho a intentar.';
        break;
    }
    _setError(kind: kind, message: message);
  }

  // Aquest mètode transforma errors del backend en missatges adequats per a la UI.
  // Evita mostrar codis interns o detalls tècnics a l’usuari.
  _SubmitErrorTranslation _translateSubmitError(ApiException error) {
    final lower = error.message.toLowerCase();

    if (lower.contains('verification rejected')) {
      if (lower.contains('device_location_too_far_from_peak')) {
        return const _SubmitErrorTranslation(
          AscentVerificationErrorKind.submitRejected,
          'Estàs massa lluny del cim per verificar l\'ascensió. '
          'Apropa\'t al cim i torna-ho a provar.',
        );
      }
      if (lower.contains('location_accuracy_too_low')) {
        return const _SubmitErrorTranslation(
          AscentVerificationErrorKind.submitRejected,
          'La precisió del GPS és massa baixa. Surt a un espai obert i '
          'torna-ho a provar.',
        );
      }
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitRejected,
        'No s\'ha pogut verificar l\'ascensió. Comprova la ubicació i la '
        'distància al cim.',
      );
    }

    if (lower.contains('storagepath') ||
        lower.contains('storage path') ||
        lower.contains('namespace')) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitRejected,
        'No s\'ha pogut associar la foto a l\'ascensió. Torna a fer-ne '
        'una i torna-ho a provar.',
      );
    }

    if (lower.contains('a verification photo is required')) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitRejected,
        'Cal una foto per verificar el cim.',
      );
    }

    if (lower.contains('peak not found')) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitRejected,
        'Aquest cim ja no està disponible. Torna a obrir la verificació.',
      );
    }

    if (lower.contains('peak does not have valid coordinates')) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitRejected,
        'Aquest cim no té coordenades vàlides al catàleg, així que no '
        'es pot verificar amb la ubicació.',
      );
    }

    if (lower.contains('cannot be in the future')) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitRejected,
        'L\'hora del dispositiu és incorrecta. Revisa el rellotge del '
        'mòbil i torna-ho a provar.',
      );
    }

    if (lower.contains('trigat massa') || lower.contains('timeout')) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitNetwork,
        'La pujada ha trigat massa. Comprova la cobertura i torna-ho '
        'a provar.',
      );
    }

    if (error.statusCode == 401) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitSessionExpired,
        'La sessió ha caducat. Torna a entrar per verificar el cim.',
      );
    }

    if (error.statusCode != null && error.statusCode! >= 500) {
      return const _SubmitErrorTranslation(
        AscentVerificationErrorKind.submitNetwork,
        'El servidor no respon ara mateix. Torna-ho a provar d\'aquí '
        'a una estona.',
      );
    }

    return const _SubmitErrorTranslation(
      AscentVerificationErrorKind.submitUnknown,
      'No s\'ha pogut crear l\'ascensió verificada. Revisa la connexió '
      'i torna-ho a provar.',
    );
  }

  // Aquest mètode centralitza la notificació de canvis.
  // Evita actualitzar la vista quan el controller ja s’ha tancat.
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