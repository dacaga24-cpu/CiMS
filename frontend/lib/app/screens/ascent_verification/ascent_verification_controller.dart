import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// Aquest controller gestiona l’inici del flux de verificació ràpida.
// Captura la ubicació del dispositiu i obre la càmera des de l’app,
// deixant preparada una evidència local abans de crear l’ascensió verificada.
class AscentVerificationController extends ChangeNotifier {
  AscentVerificationController({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  bool _isPreparingCapture = false;
  String? _message;
  String? _errorMessage;
  Position? _position;
  DateTime? _capturedAt;
  Uint8List? _photoBytes;

  bool get isPreparingCapture => _isPreparingCapture;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  Position? get position => _position;
  DateTime? get capturedAt => _capturedAt;
  Uint8List? get photoBytes => _photoBytes;
  bool get hasEvidence => _position != null && _photoBytes != null;

  Future<void> prepareCapture() async {
    if (_isPreparingCapture) {
      return;
    }

    _isPreparingCapture = true;
    _message = null;
    _errorMessage = null;
    _position = null;
    _capturedAt = null;
    _photoBytes = null;
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

      _photoBytes = await pickedImage.readAsBytes();
      _message = 'Foto i ubicació capturades correctament.';
    } catch (error) {
      debugPrint('[AscentVerificationController] Capture error: $error');
      _errorMessage =
          'No s\'ha pogut preparar la verificació. Revisa els permisos de càmera i ubicació.';
    } finally {
      _isPreparingCapture = false;
      notifyListeners();
    }
  }

  void createVerifiedAscent() {
    if (!hasEvidence) {
      _errorMessage =
          'Cal capturar una foto i la ubicació abans de crear l’ascensió verificada.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _message =
        'Evidència preparada. El següent pas serà enviar-la al backend per crear l’ascensió verificada.';
    notifyListeners();
  }

  void completeLater() {
    if (!hasEvidence) {
      _errorMessage =
          'Cal capturar una foto i la ubicació abans de guardar la verificació.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _message =
        'Evidència preparada per completar més endavant quan el backend permeti guardar-la.';
    notifyListeners();
  }

  Future<void> retryCapture() async {
    await prepareCapture();
  }

  // Aquest mètode comprova els permisos i obté la posició actual del dispositiu.
  // La ubicació capturada serà la base de la futura verificació de l’ascensió.
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