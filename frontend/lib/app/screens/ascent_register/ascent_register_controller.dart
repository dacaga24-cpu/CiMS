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
const int _maxPhotoWidth = 1920;
const int _maxPhotoHeight = 1920;
const int _photoJpegQuality = 82;
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
// Controla la data, les notes, les validacions, el desat amb backend i la
// sincronització de l’estat del cim quan l’ascensió s’ha registrat correctament.
class AscentRegisterController extends ChangeNotifier {
  AscentRegisterController({
    required this.peakId,
    DateTime? initialDate,
    RegisterAscentUseCase? registerAscentUseCase,
    PeakStatusStore? peakStatusStore,
    UserStatsRefreshStore? userStatsRefreshStore,
    UploadAscentPhotoUseCase? uploadAscentPhotoUseCase,
    ImagePicker? imagePicker,
  })  : _selectedAscentDate = DateUtils.dateOnly(initialDate ?? DateTime.now()),
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
  // data seleccionada, càrrega, errors, navegació i avisos puntuals.
  DateTime _selectedAscentDate;
  bool _disposed = false;

  bool isLoading = false;
  bool showValidation = false;
  String? errorMessage;

  // Aquest bloc manté l’estat de la foto seleccionada.
  // La previsualització permet ensenyar la imatge al formulari i la ruta pujada s’envia al backend.
  Uint8List? selectedPhotoPreviewBytes;
  AscentUploadPhoto? _uploadedPhoto;
  bool isUploadingPhoto = false;
  String? photoErrorMessage;

  AscentRegisterNavigationDestination _destination =
      AscentRegisterNavigationDestination.none;
  AscentRegisterFeedback _feedback = AscentRegisterFeedback.none;

  DateTime get selectedAscentDate => _selectedAscentDate;

  // Aquest valor preparat permet mostrar la data del formulari
  // en un format clar i directe per a l’usuari.
  String get formattedAscentDate => _formatDate(_selectedAscentDate);

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
  // En aquesta iteració només es permet una foto opcional per ascensió.
  List<AscentUploadPhoto> get _photosForSubmit {
    final uploadedPhoto = _uploadedPhoto;

    if (uploadedPhoto == null) {
      return const [];
    }

    return [uploadedPhoto];
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

  // Aquest mètode neteja els errors quan l’usuari modifica les notes.
  // Ajuda a evitar que es mantinguin avisos antics després de corregir el formulari.
  void onNotesChanged(String value) {
    errorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode obre el selector d’imatges, prepara la foto en format JPEG
  // i la puja a l’emmagatzematge abans de guardar l’ascensió.
  Future<void> onPhotoTap() async {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    photoErrorMessage = null;
    errorMessage = null;
    isUploadingPhoto = true;
    _safeNotifyListeners();

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (pickedImage == null) {
        return;
      }

      final originalBytes = await pickedImage.readAsBytes();

      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: _maxPhotoWidth,
        minHeight: _maxPhotoHeight,
        quality: _photoJpegQuality,
        format: CompressFormat.jpeg,
      );

      final uploadedPhoto = await _uploadAscentPhotoUseCase(
        bytes: compressedBytes,
        mimeType: _photoMimeType,
        isPrimary: true,
      );

      if (_disposed) {
        return;
      }

      selectedPhotoPreviewBytes = compressedBytes;
      _uploadedPhoto = uploadedPhoto;
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      photoErrorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      photoErrorMessage = 'No s\'ha pogut preparar la foto';
    } finally {
      if (!_disposed) {
        isUploadingPhoto = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode elimina la foto del formulari abans d’enviar l’ascensió.
  // Només neteja l’estat local perquè la imatge encara no està associada a cap registre definitiu.
  void onRemovePhotoTap() {
    if (isLoading || isUploadingPhoto) {
      return;
    }

    selectedPhotoPreviewBytes = null;
    _uploadedPhoto = null;
    photoErrorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode confirma el formulari i envia l’ascensió al backend.
  // Si el registre funciona, també marca el cim com a completat i avisa
  // que les estadístiques s’han de tornar a carregar.
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
  // Ara mateix només cal controlar que la data no sigui futura i que les notes no superin el límit.
  bool _isValidForm() {
    final today = DateUtils.dateOnly(DateTime.now());

    if (_selectedAscentDate.isAfter(today)) {
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
