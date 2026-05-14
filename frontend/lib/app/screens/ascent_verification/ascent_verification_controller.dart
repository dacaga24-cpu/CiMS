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

// Aquest enum indica si la pantalla ha de navegar després de crear l’ascensió.
// Permet separar la decisió del controller de la navegació real de la pantalla.
enum AscentVerificationDestination {
  none,
  editAscent,
  back,
}

// Aquest enum identifica el tipus d’error que ha aturat el flux de verificació.
// La pantalla l’utilitza per oferir l’acció correcta (reintentar, obrir ajustos…).
// Quan no hi ha error actiu, el controller exposa errorKind = null (per això
// no hi ha cap valor "none" aquí: representem l’absència d’error amb null).
enum AscentVerificationErrorKind {
  // Errors del flux de captura d’ubicació.
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationTimeout,
  locationUnknown,

  // Errors del flux de la càmera.
  cameraPermissionDenied,
  cameraCancelled,
  cameraFailed,

  // Errors de l’enviament final al backend. Es desglossen perquè la pantalla
  // pugui oferir l’acció correcta (reintentar, tornar al login, etc.).
  submitNetwork,
  submitRejected,
  submitSessionExpired,
  submitUnknown,
}

// Aquesta excepció interna porta el tipus d’error fins al catch del controller
// sense barrejar-se amb altres excepcions del sistema.
class _LocationCaptureFailure implements Exception {
  const _LocationCaptureFailure(this.kind);

  final AscentVerificationErrorKind kind;
}

// Parell d’ús intern que retorna _translateSubmitError per propagar alhora
// el tipus i el missatge ja traduït a català, sense exposar-los com a tuples
// (els records requeririen Dart 3+ i ara la SDK mínima del projecte és 2.19).
class _SubmitErrorTranslation {
  const _SubmitErrorTranslation(this.kind, this.message);

  final AscentVerificationErrorKind kind;
  final String message;
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
        _uploadAscentPhotoUseCase = uploadAscentPhotoUseCase ??
            UploadAscentPhotoUseCase(ApiClientImpl()),
        _createVerifiedAscentUseCase = createVerifiedAscentUseCase ??
            CreateVerifiedAscentUseCase(ApiClientImpl()),
        _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore;

  // Aquest temps màxim evita que la captura de GPS quedi penjada
  // quan el dispositiu no aconsegueix una posició fiable.
  static const Duration _locationTimeout = Duration(seconds: 20);

  // Aquesta configuració redueix el pes de la foto de verificació abans de pujar-la.
  // FlutterImageCompress interpreta minWidth/minHeight com a dimensions mínimes
  // del costat resultant; manté la imatge dins d’una caixa de 1920px sense
  // ampliar-la si ja és més petita. Els valors coincideixen amb el registre
  // normal d’ascensions (vegeu AscentRegisterController) i amb el límit de
  // 8 MB del bucket configurat al backend.
  static const int _minPhotoWidth = 1920;
  static const int _minPhotoHeight = 1920;
  static const int _photoJpegQuality = 82;
  static const String _photoMimeTypeAfterCompression = 'image/jpeg';

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

  // Aquest getter indica si l’error actual es resol obrint la configuració del
  // sistema (servei d’ubicació desactivat). A web no s’ofereix perquè el botó
  // natiu d’ubicació del sistema no aplica al navegador. La pantalla l’utilitza
  // per decidir si mostra el botó corresponent.
  bool get errorNeedsLocationSettings =>
      !kIsWeb &&
      _errorKind == AscentVerificationErrorKind.locationServiceDisabled;

  // Aquest getter indica si l’error actual es resol obrint la configuració de
  // l’app (permís denegat per sempre o denegat per la càmera). A web tampoc
  // s’ofereix perquè els permisos del navegador es gestionen des de la
  // mateixa pestanya, no des d’una pantalla d’ajustos de l’aplicació.
  bool get errorNeedsAppSettings =>
      !kIsWeb &&
      (_errorKind ==
              AscentVerificationErrorKind.locationPermissionDeniedForever ||
          _errorKind == AscentVerificationErrorKind.cameraPermissionDenied);

  // Aquest mètode neteja la navegació pendent després que la pantalla l’hagi consumit.
  // Evita repetir la mateixa navegació en futures notificacions del controller.
  void consumeNavigation() {
    _destination = AscentVerificationDestination.none;
  }

  // Aquest helper garanteix que _errorKind i _errorMessage es mantenen
  // sempre coherents: tots dos s’actualitzen alhora i no hi ha cap branca
  // que oblidi cap dels dos camps. Passar kind=null neteja l’error.
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

  // Aquest mètode inicia la verificació capturant ubicació i data.
  // Després carrega els cims propers perquè l’usuari triï el cim abans de fer la foto.
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
  // El backend rebrà aquest cim juntament amb la foto i la ubicació capturada.
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
      _setError(
        kind: AscentVerificationErrorKind.locationUnknown,
        message:
            'Cal capturar la ubicació abans de fer la foto de verificació.',
      );
      _safeNotifyListeners();
      return;
    }

    if (_selectedNearbyPeakCandidate == null) {
      // Aquest avís és una pista de validació de formulari, no un estat
      // d’error del flux: per això no s’associa cap kind concret.
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

      // La foto es comprimeix abans de pujar-la perquè les càmeres dels mòbils
      // generen fitxers de diversos megabytes que poden superar el temps màxim
      // d’espera en xarxes mòbils. La compressió i la conversió a JPEG mantenen
      // l’evidència visible amb un pes molt inferior i compatible amb el bucket.
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: _minPhotoWidth,
        minHeight: _minPhotoHeight,
        quality: _photoJpegQuality,
        format: CompressFormat.jpeg,
      );

      // Si el plugin nadiu no pot processar la imatge (formats poc habituals,
      // memòria insuficient, errors interns) retorna una llista buida sense
      // llançar excepció. Si ho deixem passar, intentaríem pujar 0 bytes i
      // l’error apareixeria molt més tard amb un missatge poc útil.
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
      // Aquests dos missatges són pistes de validació de formulari (estat
      // incomplet abans de submit), no errors d’un flux iniciat. Per això
      // s’associen sense kind concret.
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
      // Loguem el missatge cru del backend per facilitar el diagnòstic, però
      // a l’usuari li mostrem un text traduït i sense fragments tècnics com
      // paths del bucket o codis interns (vegeu _humanReadableSubmitError).
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
        // "No hi ha cims propers" és un avís d’estat (no ha fallat cap petició),
        // per això no es marca cap kind del flux: la UI només mostra el missatge.
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
  // En web es deixa que el navegador gestioni el permís quan l’usuari inicia el flux.
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

  // Aquest mètode tradueix el tipus d’error d’ubicació en un missatge clar
  // i marca el tipus perquè la pantalla mostri l’acció més útil. Els missatges
  // canvien en web perquè a l’app les opcions de “configuració del sistema”
  // no apliquen de la mateixa manera que al navegador.
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

  // Aquest mètode tradueix els errors del backend a un tipus + missatge en
  // català sense exposar detalls interns (paths del bucket, codis com
  // DEVICE_LOCATION_*…). El missatge cru es manté als logs per al diagnòstic,
  // però no arriba a la UI.
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
