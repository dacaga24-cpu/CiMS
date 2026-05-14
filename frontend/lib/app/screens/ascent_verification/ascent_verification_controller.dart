import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/nearby_peak_candidate.dart';
import 'package:cims/core/usecase/ascents/create_verified_ascent_usecase.dart';
import 'package:cims/core/usecase/ascents/upload_ascent_photo_usecase.dart';
import 'package:cims/core/usecase/peaks/find_nearby_peaks_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// Aquest controller gestiona el flux de verificació ràpida.
// Captura ubicació i foto, proposa cims propers i envia l’evidència al backend
// per crear una ascensió verificada.
class AscentVerificationController extends ChangeNotifier {
  AscentVerificationController({
    ImagePicker? imagePicker,
    FindNearbyPeaksUseCase? findNearbyPeaksUseCase,
    UploadAscentPhotoUseCase? uploadAscentPhotoUseCase,
    CreateVerifiedAscentUseCase? createVerifiedAscentUseCase,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _findNearbyPeaksUseCase =
            findNearbyPeaksUseCase ?? FindNearbyPeaksUseCase(ApiClientImpl()),
        _uploadAscentPhotoUseCase =
            uploadAscentPhotoUseCase ?? UploadAscentPhotoUseCase(ApiClientImpl()),
        _createVerifiedAscentUseCase = createVerifiedAscentUseCase ??
            CreateVerifiedAscentUseCase(ApiClientImpl());

  final ImagePicker _imagePicker;
  final FindNearbyPeaksUseCase _findNearbyPeaksUseCase;
  final UploadAscentPhotoUseCase _uploadAscentPhotoUseCase;
  final CreateVerifiedAscentUseCase _createVerifiedAscentUseCase;

  bool _isPreparingCapture = false;
  bool _isLoadingNearbyPeaks = false;
  String? _message;
  String? _errorMessage;
  Position? _position;
  DateTime? _capturedAt;
  Uint8List? _photoBytes;
  String _photoMimeType = 'image/jpeg';
  List<NearbyPeakCandidate> _nearbyPeakCandidates = const [];
  NearbyPeakCandidate? _selectedNearbyPeakCandidate;
  Ascent? _createdAscent;

  bool get isPreparingCapture => _isPreparingCapture;
  bool get isLoadingNearbyPeaks => _isLoadingNearbyPeaks;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  Position? get position => _position;
  DateTime? get capturedAt => _capturedAt;
  Uint8List? get photoBytes => _photoBytes;
  List<NearbyPeakCandidate> get nearbyPeakCandidates => _nearbyPeakCandidates;
  NearbyPeakCandidate? get selectedNearbyPeakCandidate =>
      _selectedNearbyPeakCandidate;
  Ascent? get createdAscent => _createdAscent;
  bool get hasEvidence => _position != null && _photoBytes != null;
  bool get hasSelectedPeak => _selectedNearbyPeakCandidate != null;

  Future<void> prepareCapture() async {
    if (_isPreparingCapture) {
      return;
    }

    _isPreparingCapture = true;
    _isLoadingNearbyPeaks = false;
    _message = null;
    _errorMessage = null;
    _position = null;
    _capturedAt = null;
    _photoBytes = null;
    _photoMimeType = 'image/jpeg';
    _nearbyPeakCandidates = const [];
    _selectedNearbyPeakCandidate = null;
    _createdAscent = null;
    notifyListeners();

    try {
      _position = await _captureCurrentLocation();
      _capturedAt = DateTime.now();

      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );

      if (pickedImage == null) {
        _errorMessage = 'No s’ha fet cap foto de verificació.';
        return;
      }

      _photoMimeType = pickedImage.mimeType ?? 'image/jpeg';
      _photoBytes = await pickedImage.readAsBytes();
      _message = 'Foto i ubicació capturades correctament.';
      notifyListeners();

      await _loadNearbyPeaks();
    } catch (error) {
      debugPrint('[AscentVerificationController] Capture error: $error');
      _errorMessage =
          'No s\'ha pogut preparar la verificació. Revisa els permisos de càmera i ubicació.';
    } finally {
      _isPreparingCapture = false;
      _isLoadingNearbyPeaks = false;
      notifyListeners();
    }
  }

  // Aquest mètode selecciona el cim que l’usuari vol verificar.
  // El backend rebrà aquest cim juntament amb la foto i la ubicació capturada.
  void selectNearbyPeakCandidate(NearbyPeakCandidate candidate) {
    _selectedNearbyPeakCandidate = candidate;
    _message = 'Cim seleccionat: ${candidate.peak.name}.';
    _errorMessage = null;
    notifyListeners();
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
          'Cal capturar una foto i la ubicació abans de crear l’ascensió verificada.';
      notifyListeners();
      return;
    }

    if (selectedCandidate == null) {
      _errorMessage = 'Selecciona quin cim vols verificar.';
      notifyListeners();
      return;
    }

    _isPreparingCapture = true;
    _errorMessage = null;
    _message = completeNow
        ? 'Creant l’ascensió verificada...'
        : 'Guardant l’ascensió per completar-la més endavant...';
    notifyListeners();

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
      _message = completeNow
          ? 'Ascensió verificada creada. Ja pots completar-ne les dades.'
          : 'Ascensió verificada creada. La podràs completar més endavant des de l’historial.';
    } catch (error) {
      debugPrint('[AscentVerificationController] Submit error: $error');
      _errorMessage =
          'No s’ha pogut crear l’ascensió verificada. Revisa la connexió i torna-ho a provar.';
    } finally {
      _isPreparingCapture = false;
      notifyListeners();
    }
  }

  // Aquest mètode carrega els cims propers a la ubicació capturada.
  // Permet proposar opcions reals abans de crear l’ascensió verificada.
  Future<void> _loadNearbyPeaks() async {
    final currentPosition = _position;

    if (currentPosition == null) {
      return;
    }

    _isLoadingNearbyPeaks = true;
    notifyListeners();

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
        _errorMessage = 'No s’ha trobat cap cim proper per verificar.';
      }
    } catch (error) {
      debugPrint('[AscentVerificationController] Nearby peaks error: $error');
      _errorMessage = 'No s’han pogut carregar els cims propers.';
    }
  }

  // Aquest mètode comprova permisos i obté la posició actual del dispositiu.
  // La ubicació capturada serà la base de la verificació.
  Future<Position> _captureCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service disabled');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}