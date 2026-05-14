import 'dart:typed_data';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/ascents/register_ascent_usecase.dart';
import 'package:cims/core/usecase/ascents/upload_ascent_photo_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

// Aquest límit coincideix amb la validació del backend.
// Evita enviar notes massa llargues i permet mostrar un error abans de fer la petició.
const int _maxNotesLength = 2000;

// Aquesta configuració redueix el pes de les fotos abans de pujar-les.
// Es manté una mida suficient per veure la imatge amb qualitat dins de l’aplicació.
// FlutterImageCompress interpreta minWidth/minHeight com a dimensions mínimes
// del costat resultant, no màximes. Aquests valors limiten les fotos a una
// caixa de 1920 px mantenint l’evidència visible amb un pes molt inferior.
const int _minPhotoWidth = 1920;
const int _minPhotoHeight = 1920;
const int _photoJpegQuality = 82;
const int _maxAscentPhotos = 8;
const String _photoMimeType = 'image/jpeg';

// Aquest enum indica les accions de navegació que la vista ha de resoldre
// des de fora del controller.
enum AscentRegisterNavigationDestination {
  none,
  back,
}

// Aquest enum permet comunicar avisos puntuals a la pantalla
// sense barrejar-los amb la navegació.
enum AscentRegisterFeedback {
  none,
  saved,
}

// Aquest controller gestiona l’estat local del formulari de registre d’ascensió.
// Controla la data opcional, les notes, les fotos, les validacions, el desat amb
// backend i la sincronització de l’estat del cim quan el registre es completa.
class AscentRegisterController extends ChangeNotifier {
  AscentRegisterController({
    required this.peakId,
    DateTime? initialDate,
    RegisterAscentUseCase? registerAscentUseCase,
    PeakStatusStore? peakStatusStore,
    UserStatsRefreshStore? userStatsRefreshStore,
    UploadAscentPhotoUseCase? uploadAscentPhotoUseCase,
    ImagePicker? imagePicker,
  })  : _selectedAscentDate =
            initialDate == null ? null : DateUtils.dateOnly(initialDate),
        _registerAscentUseCase = registerAscentUseCase ??
            RegisterAscentUseCase(
              ApiClientImpl(),
            ),
        _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore,
        _uploadAscentPhotoUseCase = uploadAscentPhotoUseCase ??
            UploadAscentPhotoUseCase(
              ApiClientImpl(),
            ),
        _imagePicker = imagePicker ?? ImagePicker();

  // Aquest identificador indica a quin cim quedarà associada l’ascensió.
  // Arriba des de la pantalla de detall del cim.
  final int peakId;

  // Aquest bloc agrupa les dependències que permeten registrar l’ascensió,
  // mantenir sincronitzat l’estat compartit dels cims i avisar les estadístiques.
  final RegisterAscentUseCase _registerAscentUseCase;
  final PeakStatusStore _peakStatusStore;
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquestes dependències gestionen la selecció local de la imatge
  // i la seva pujada temporal abans de registrar l’ascensió.
  final UploadAscentPhotoUseCase _uploadAscentPhotoUseCase;
  final ImagePicker _imagePicker;

  // Aquest camp guarda el text lliure que l’usuari escriu
  // per deixar observacions sobre l’ascensió.
  final TextEditingController notesController = TextEditingController();

  // Aquest bloc manté l’estat intern del formulari:
  // data opcional, càrrega, errors, navegació i avisos puntuals.
  DateTime? _selectedAscentDate;
  bool _disposed = false;

  bool isLoading = false;
  bool showValidation = false;
  String? errorMessage;

  // Aquest bloc manté l’estat de les fotos seleccionades.
  // Les previsualitzacions permeten ensenyar miniatures i les rutes pujades s’envien al backend.
  final List<Uint8List> selectedPhotoPreviewBytes = [];
  final List<AscentUploadPhoto> _uploadedPhotos = [];
  bool isUploadingPhoto = false;
  String? photoErrorMessage;

  // Aquest valor indica quantes fotos hi ha seleccionades al formulari.
  int get selectedPhotosCount => selectedPhotoPreviewBytes.length;

  // Aquest valor indica si encara es poden afegir més fotos a l’ascensió.
  bool get canAddMorePhotos => selectedPhotosCount < _maxAscentPhotos;

  // Aquest valor exposa el límit màxim de fotos permès per ascensió.
  int get maxAscentPhotos => _maxAscentPhotos;

  AscentRegisterNavigationDestination _destination =
      AscentRegisterNavigationDestination.none;
  AscentRegisterFeedback _feedback = AscentRegisterFeedback.none;

  DateTime? get selectedAscentDate => _selectedAscentDate;

  // Aquest valor indica si el formulari té una data seleccionada.
  // Permet a la pantalla mostrar l’opció de netejar-la només quan cal.
  bool get hasSelectedAscentDate => _selectedAscentDate != null;

  // Aquest valor preparat mostra la data seleccionada o un text d’ajuda
  // quan l’usuari encara no ha triat cap data.
  String get formattedAscentDate {
    final selectedDate = _selectedAscentDate;

    if (selectedDate == null) {
      return 'Seleccionar data';
    }

    return _formatDate(selectedDate);
  }

  // Aquest valor indica si el registre s’està intentant guardar sense data.
  // La pantalla l’utilitza per demanar confirmació abans d’enviar el formulari.
  bool get needsMissingDateConfirmation => _selectedAscentDate == null;

  AscentRegisterNavigationDestination get destination => _destination;

  AscentRegisterFeedback get feedback => _feedback;

  // Aquest getter indica si les notes superen el límit acceptat.
  // La pantalla el pot utilitzar per mostrar l’error visual corresponent.
  bool get hasInvalidNotes =>
      showValidation && notesController.text.length > _maxNotesLength;

  // Aquest getter retorna les notes netes, o null si l’usuari no ha escrit res.
  // Així el backend rep només informació útil.
  String? get _normalizedNotes {
    final notes = notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }

  // Aquest getter prepara la llista de fotos que s’enviarà al backend.
  // Es marca com a principal la primera foto visible del formulari.
  List<AscentUploadPhoto> get _photosForSubmit {
    return _uploadedPhotos.asMap().entries.map((entry) {
      final index = entry.key;
      final photo = entry.value;

      return AscentUploadPhoto(
        storagePath: photo.storagePath,
        isPrimary: index == 0,
      );
    }).toList();
  }

  // Aquest mètode actualitza la data seleccionada del registre.
  // La pantalla li passa la data escollida des del selector de calendari.
  void onAscentDateChanged(DateTime value) {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    _selectedAscentDate = DateUtils.dateOnly(value);
    errorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode deixa el registre sense data.
  // Serveix per als casos en què l’usuari sap que ha completat el cim,
  // però no recorda el dia exacte de l’ascensió.
  void onClearAscentDateTap() {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    _selectedAscentDate = null;
    errorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode neteja els errors quan l’usuari modifica les notes.
  // Ajuda a evitar que es mantinguin avisos antics després de corregir el formulari.
  void onNotesChanged(String value) {
    errorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode obre el selector d’imatges, prepara les fotos en format JPEG
  // i les puja a l’emmagatzematge abans de guardar l’ascensió.
  Future<void> onPhotoTap() async {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    if (!canAddMorePhotos) {
      photoErrorMessage =
          'Només es poden afegir $_maxAscentPhotos fotos per ascensió';
      _safeNotifyListeners();
      return;
    }

    photoErrorMessage = null;
    errorMessage = null;
    _safeNotifyListeners();

    try {
      final remainingSlots =
          _maxAscentPhotos - selectedPhotoPreviewBytes.length;

      final pickedImages = await _imagePicker.pickMultiImage(
        requestFullMetadata: false,
      );

      if (pickedImages.isEmpty) {
        return;
      }

      final imagesToUpload = pickedImages.take(remainingSlots).toList();

      isUploadingPhoto = true;
      _safeNotifyListeners();

      for (final pickedImage in imagesToUpload) {
        final originalBytes = await pickedImage.readAsBytes();

        final compressedBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: _minPhotoWidth,
          minHeight: _minPhotoHeight,
          quality: _photoJpegQuality,
          format: CompressFormat.jpeg,
        );

        final uploadedPhoto = await _uploadAscentPhotoUseCase(
          bytes: compressedBytes,
          mimeType: _photoMimeType,
          isPrimary: _uploadedPhotos.isEmpty,
        );

        if (_disposed) {
          return;
        }

        selectedPhotoPreviewBytes.add(compressedBytes);
        _uploadedPhotos.add(uploadedPhoto);
      }

      if (pickedImages.length > remainingSlots) {
        photoErrorMessage =
            'S\'han afegit només $remainingSlots fotos perquè el límit és $_maxAscentPhotos';
      }
    } on ApiException catch (error) {
      if (_disposed) return;
      photoErrorMessage = error.message;
    } catch (error) {
      if (_disposed) return;
      debugPrint('[AscentRegisterController] Photo error: $error');
      photoErrorMessage = 'No s\'han pogut preparar les fotos';
    } finally {
      if (!_disposed) {
        isUploadingPhoto = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode elimina una foto concreta del formulari abans d’enviar l’ascensió.
  // Només neteja l’estat local perquè la imatge encara no està associada a cap registre definitiu.
  void onRemovePhotoTap(int index) {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    if (index < 0 || index >= selectedPhotoPreviewBytes.length) {
      return;
    }

    selectedPhotoPreviewBytes.removeAt(index);
    _uploadedPhotos.removeAt(index);
    photoErrorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode confirma el formulari i envia l’ascensió al backend.
  // Si el registre funciona, el cim queda completat i les estadístiques
  // es marquen per tornar-se a carregar.
  Future<void> onConfirmTap() async {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    showValidation = true;
    errorMessage = null;

    if (!_isValidForm()) {
      _safeNotifyListeners();
      return;
    }

    isLoading = true;
    _safeNotifyListeners();

    try {
      await _registerAscentUseCase(
        peakId: peakId,
        ascentDate: _selectedAscentDate,
        notes: _normalizedNotes,
        photos: _photosForSubmit,
      );

      if (_disposed) {
        return;
      }

      _markPeakAsCompletedInStore();
      _userStatsRefreshStore.notifyStatsChanged();

      _feedback = AscentRegisterFeedback.saved;
      _destination = AscentRegisterNavigationDestination.back;
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      errorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      errorMessage = 'No s\'ha pogut registrar l\'ascensió';
    } finally {
      if (!_disposed) {
        isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode indica a la vista que l’usuari vol sortir del formulari.
  void onCancelTap() {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    _destination = AscentRegisterNavigationDestination.back;
    _safeNotifyListeners();
  }

  // Aquest mètode reinicia l’acció de navegació després que la vista l’hagi resolt.
  void consumeNavigation() {
    _destination = AscentRegisterNavigationDestination.none;
  }

  // Aquest mètode reinicia l’avís puntual després que la vista ja l’hagi mostrat.
  void consumeFeedback() {
    _feedback = AscentRegisterFeedback.none;
  }

  // Aquest mètode valida les dades abans d’enviar-les al backend.
  // La data és opcional, però si existeix no pot ser futura.
  bool _isValidForm() {
    final selectedDate = _selectedAscentDate;
    final today = DateUtils.dateOnly(DateTime.now());

    if (selectedDate != null && selectedDate.isAfter(today)) {
      errorMessage = 'La data de l\'ascensió no pot ser futura';
      return false;
    }

    if (notesController.text.length > _maxNotesLength) {
      errorMessage =
          'Les notes no poden superar els $_maxNotesLength caràcters';
      return false;
    }

    return true;
  }

  // Aquest mètode sincronitza l’estat local del cim després d’un registre correcte.
  // El backend marca el cim com a completat, i el frontend reflecteix aquest canvi
  // sense obligar l’usuari a recarregar el catàleg o el detall.
  void _markPeakAsCompletedInStore() {
    final currentStatus =
        _peakStatusStore.getStatus(peakId) ?? PeakStatus.emptyForPeak(peakId);

    _peakStatusStore.setStatus(
      currentStatus.copyWith(
        isCompleted: true,
      ),
    );
  }

  // Aquí s’alliberen els recursos del formulari abans de tancar-lo,
  // evitant que quedin controladors actius quan la pantalla desapareix.
  @override
  void dispose() {
    _disposed = true;
    notesController.dispose();
    super.dispose();
  }

  // Aquest mètode centralitza la notificació de canvis
  // i evita intentar actualitzar la vista quan el controller ja s’ha tancat.
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Aquest mètode transforma la data en un text llegible per al formulari.
  String _formatDate(DateTime date) {
    final day = _twoDigits(date.day);
    final month = _twoDigits(date.month);
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // Aquest suport assegura que dia i mes sempre es mostrin
  // amb dos dígits per mantenir un format visual uniforme.
  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}