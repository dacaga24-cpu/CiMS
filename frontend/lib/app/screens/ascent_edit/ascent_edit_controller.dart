import 'dart:typed_data';

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/ascents/add_ascent_photos_usecase.dart';
import 'package:cims/core/usecase/ascents/delete_ascent_photo_usecase.dart';
import 'package:cims/core/usecase/ascents/delete_ascent_usecase.dart';
import 'package:cims/core/usecase/ascents/get_ascent_photos_usecase.dart';
import 'package:cims/core/usecase/ascents/update_ascent_usecase.dart';
import 'package:cims/core/usecase/ascents/upload_ascent_photo_usecase.dart';
import 'package:cims/core/usecase/peaks/get_peak_status_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

// Aquest límit coincideix amb la validació del backend.
// Evita guardar notes massa llargues i permet mostrar un error abans d’enviar canvis.
const int _maxNotesLength = 2000;

// Aquest límit coincideix amb la validació del backend.
// Evita que una ascensió pugui acumular més fotos de les permeses.
const int _maxAscentPhotos = 8;

// Aquests valors defineixen com es preparen les imatges abans de pujar-les.
// Es fa servir JPEG per reduir pes i mantenir una qualitat suficient per a galeria.
const int _minPhotoWidth = 1920;
const int _minPhotoHeight = 1920;
const int _photoJpegQuality = 82;
const String _photoMimeType = 'image/jpeg';

// Aquest enum indica les accions de navegació que la vista ha de resoldre
// des de fora del controller.
enum AscentEditNavigationDestination {
  none,
  back,
}

// Aquest enum permet comunicar avisos puntuals a la pantalla
// sense barrejar-los amb la navegació.
enum AscentEditFeedback {
  none,
  saved,
  deleted,
}

// Aquest controller gestiona l’estat local de l’edició d’una ascensió.
// Rep una ascensió existent i prepara el formulari amb la data opcional,
// les notes i les fotos ja registrades.
class AscentEditController extends ChangeNotifier {
  AscentEditController({
    required this.ascent,
    UpdateAscentUseCase? updateAscentUseCase,
    GetAscentPhotosUseCase? getAscentPhotosUseCase,
    DeleteAscentPhotoUseCase? deleteAscentPhotoUseCase,
    DeleteAscentUseCase? deleteAscentUseCase,
    AddAscentPhotosUseCase? addAscentPhotosUseCase,
    UploadAscentPhotoUseCase? uploadAscentPhotoUseCase,
    GetPeakStatusUseCase? getPeakStatusUseCase,
    PeakStatusStore? peakStatusStore,
    UserStatsRefreshStore? userStatsRefreshStore,
    ImagePicker? imagePicker,
  })  : _selectedAscentDate = ascent.ascentDate == null
            ? null
            : DateUtils.dateOnly(ascent.ascentDate!),
        notesController = TextEditingController(text: ascent.notes ?? ''),
        _updateAscentUseCase =
            updateAscentUseCase ?? UpdateAscentUseCase(ApiClientImpl()),
        _getAscentPhotosUseCase =
            getAscentPhotosUseCase ?? GetAscentPhotosUseCase(ApiClientImpl()),
        _deleteAscentPhotoUseCase = deleteAscentPhotoUseCase ??
            DeleteAscentPhotoUseCase(ApiClientImpl()),
        _deleteAscentUseCase =
            deleteAscentUseCase ?? DeleteAscentUseCase(ApiClientImpl()),
        _addAscentPhotosUseCase =
            addAscentPhotosUseCase ?? AddAscentPhotosUseCase(ApiClientImpl()),
        _uploadAscentPhotoUseCase = uploadAscentPhotoUseCase ??
            UploadAscentPhotoUseCase(ApiClientImpl()),
        _getPeakStatusUseCase =
            getPeakStatusUseCase ?? GetPeakStatusUseCase(ApiClientImpl()),
        _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore,
        _imagePicker = imagePicker ?? ImagePicker();

  // Aquesta ascensió és el registre original que l’usuari vol consultar o editar.
  final Ascent ascent;

  // Aquest camp guarda les notes de l’ascensió i ja ve inicialitzat
  // amb el text que l’usuari havia registrat anteriorment.
  final TextEditingController notesController;

  // Aquest cas d’ús permet guardar els canvis de l’ascensió al backend.
  final UpdateAscentUseCase _updateAscentUseCase;

  // Aquest cas d’ús permet carregar les fotos ja associades a l’ascensió.
  final GetAscentPhotosUseCase _getAscentPhotosUseCase;

  // Aquest cas d’ús permet eliminar fotos associades a l’ascensió.
  final DeleteAscentPhotoUseCase _deleteAscentPhotoUseCase;

  // Aquest cas d’ús permet eliminar l’ascensió completa.
  final DeleteAscentUseCase _deleteAscentUseCase;

  // Aquest cas d’ús associa fotos noves a una ascensió ja existent.
  final AddAscentPhotosUseCase _addAscentPhotosUseCase;

  // Aquest cas d’ús puja una imatge al bucket i retorna la ruta que després
  // es vincula amb l’ascensió.
  final UploadAscentPhotoUseCase _uploadAscentPhotoUseCase;

  // Aquest selector permet reutilitzar el mateix flux visual que el registre
  // d’ascensió per triar una o diverses imatges.
  final ImagePicker _imagePicker;

  // Aquestes dependències mantenen sincronitzat l’estat global després dels canvis.
  // Permeten que catàleg, mapa, dashboard i estadístiques reflecteixin l’edició.
  final GetPeakStatusUseCase _getPeakStatusUseCase;
  final PeakStatusStore _peakStatusStore;
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquest bloc manté l’estat intern del formulari:
  // data opcional, càrrega, errors, navegació i avisos puntuals.
  DateTime? _selectedAscentDate;
  bool _disposed = false;

  bool isLoading = false;
  bool isDeletingAscent = false;
  bool showValidation = false;
  String? errorMessage;

  AscentEditNavigationDestination _destination =
      AscentEditNavigationDestination.none;
  AscentEditFeedback _feedback = AscentEditFeedback.none;

  DateTime? get selectedAscentDate => _selectedAscentDate;

  // Aquest bloc guarda l’estat de les fotos existents de l’ascensió.
  List<AscentPhoto> photos = const [];
  bool isLoadingPhotos = false;
  bool isUploadingPhotos = false;
  String? photosErrorMessage;
  int? deletingPhotoId;

  bool get hasSelectedAscentDate => _selectedAscentDate != null;

  int get maxAscentPhotos => _maxAscentPhotos;

  int get photosCount => photos.length;

  bool get canAddMorePhotos => photos.length < _maxAscentPhotos;

  bool get isBusy =>
      isLoading ||
      isDeletingAscent ||
      isLoadingPhotos ||
      isUploadingPhotos ||
      deletingPhotoId != null;

  // Aquest getter indica si la data està protegida per una verificació.
  // Quan és així, la pantalla pot mostrar-la com a no editable.
  bool get isDateLocked => ascent.isDateLocked;

  String get formattedAscentDate {
    final selectedDate = _selectedAscentDate;

    if (selectedDate == null) {
      return 'Seleccionar data';
    }

    return _formatDate(selectedDate);
  }

  AscentEditNavigationDestination get destination => _destination;

  AscentEditFeedback get feedback => _feedback;

  bool get hasInvalidNotes =>
      showValidation && notesController.text.length > _maxNotesLength;

  bool get hasChanges {
    final originalDate = ascent.ascentDate == null
        ? null
        : DateUtils.dateOnly(ascent.ascentDate!);
    final originalNotes = (ascent.notes ?? '').trim();
    final currentNotes = notesController.text.trim();

    final hasDateChanged = isDateLocked
        ? false
        : originalDate == null
            ? _selectedAscentDate != null
            : _selectedAscentDate == null ||
                !_selectedAscentDate!.isAtSameMomentAs(originalDate);

    return hasDateChanged || currentNotes != originalNotes;
  }

  Future<void> initialize() async {
    await _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    isLoadingPhotos = true;
    photosErrorMessage = null;
    _safeNotifyListeners();

    try {
      final loadedPhotos = await _getAscentPhotosUseCase(ascent.id);

      if (_disposed) return;

      photos = loadedPhotos;
    } on ApiException catch (error) {
      if (_disposed) return;

      photos = const [];
      photosErrorMessage = error.message;
    } catch (_) {
      if (_disposed) return;

      photos = const [];
      photosErrorMessage = 'No s\'han pogut carregar les fotos';
    } finally {
      if (!_disposed) {
        isLoadingPhotos = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> onRetryPhotosTap() {
    return _loadPhotos();
  }

  // Aquest mètode permet afegir fotos noves a una ascensió ja creada.
  // Reutilitza el patró del registre: seleccionar, comprimir, pujar al bucket
  // i després associar els storagePath resultants amb l’ascensió existent.
  Future<void> onAddPhotosTap() async {
    if (isBusy) {
      return;
    }

    if (!canAddMorePhotos) {
      photosErrorMessage =
          'Només es poden afegir $_maxAscentPhotos fotos per ascensió';
      _safeNotifyListeners();
      return;
    }

    photosErrorMessage = null;
    _safeNotifyListeners();

    try {
      final remainingSlots = _maxAscentPhotos - photos.length;

      final pickedImages = await _imagePicker.pickMultiImage(
        requestFullMetadata: false,
      );

      if (_disposed || pickedImages.isEmpty) {
        return;
      }

      final imagesToUpload = pickedImages.take(remainingSlots).toList();

      isUploadingPhotos = true;
      _safeNotifyListeners();

      final uploadedPhotos = <AscentUploadPhoto>[];

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
          bytes: Uint8List.fromList(compressedBytes),
          mimeType: _photoMimeType,
          isPrimary: photos.isEmpty && uploadedPhotos.isEmpty,
        );

        if (_disposed) {
          return;
        }

        uploadedPhotos.add(uploadedPhoto);
      }

      if (uploadedPhotos.isEmpty) {
        return;
      }

      await _addAscentPhotosUseCase(
        ascentId: ascent.id,
        photos: uploadedPhotos,
      );

      if (_disposed) {
        return;
      }

      if (pickedImages.length > remainingSlots) {
        photosErrorMessage =
            'S\'han afegit només $remainingSlots fotos perquè el límit és $_maxAscentPhotos';
      }

      await _loadPhotos();

      if (_disposed) {
        return;
      }

      _userStatsRefreshStore.notifyStatsChanged();
    } on ApiException catch (error) {
      if (_disposed) return;

      photosErrorMessage = error.message;
    } catch (error) {
      if (_disposed) return;

      debugPrint('[AscentEditController] Add photos error: $error');
      photosErrorMessage = 'No s\'han pogut afegir les fotos';
    } finally {
      if (!_disposed) {
        isUploadingPhotos = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode elimina una foto individual si no forma part de la verificació.
  // La foto d’evidència queda protegida perquè és la prova que valida l’ascensió.
  Future<void> onDeletePhotoTap(int photoId) async {
    if (isBusy) {
      return;
    }

    final photo = _findPhotoById(photoId);

    if (photo == null) {
      photosErrorMessage = 'No s\'ha trobat la foto seleccionada';
      _safeNotifyListeners();
      return;
    }

    if (photo.isVerificationEvidence) {
      photosErrorMessage =
          'La foto d’evidència no es pot eliminar individualment. Pots eliminar l’ascensió completa si s’ha creat per error.';
      _safeNotifyListeners();
      return;
    }

    deletingPhotoId = photoId;
    photosErrorMessage = null;
    _safeNotifyListeners();

    try {
      await _deleteAscentPhotoUseCase(photoId);

      if (_disposed) return;

      photos = photos.where((photo) => photo.id != photoId).toList();
      _userStatsRefreshStore.notifyStatsChanged();
    } on ApiException catch (error) {
      if (_disposed) return;

      photosErrorMessage = error.message;
    } catch (_) {
      if (_disposed) return;

      photosErrorMessage = 'No s\'ha pogut eliminar la foto';
    } finally {
      if (!_disposed) {
        deletingPhotoId = null;
        _safeNotifyListeners();
      }
    }
  }

  String? get normalizedNotes {
    final notes = notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }

  void onAscentDateChanged(DateTime value) {
    if (isBusy || isDateLocked) {
      return;
    }

    _selectedAscentDate = DateUtils.dateOnly(value);
    errorMessage = null;
    _safeNotifyListeners();
  }

  void onClearAscentDateTap() {
    if (isBusy || isDateLocked) {
      return;
    }

    _selectedAscentDate = null;
    errorMessage = null;
    _safeNotifyListeners();
  }

  void onNotesChanged(String value) {
    errorMessage = null;
    _safeNotifyListeners();
  }

  Future<void> onSaveTap() async {
    if (isBusy) {
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
      await _updateAscentUseCase(
        ascentId: ascent.id,
        ascentDate: _selectedAscentDate,
        includeAscentDate: !isDateLocked,
        notes: normalizedNotes,
      );

      if (_disposed) return;

      await _syncAfterAscentChange();

      if (_disposed) return;

      _feedback = AscentEditFeedback.saved;
      _destination = AscentEditNavigationDestination.back;
    } on ApiException catch (error) {
      if (_disposed) return;

      errorMessage = error.message;
    } catch (_) {
      if (_disposed) return;

      errorMessage = 'No s\'ha pogut actualitzar l\'ascensió';
    } finally {
      if (!_disposed) {
        isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode elimina l’ascensió completa.
  // Si era l’última ascensió del cim, el backend deixa el cim com a no completat.
  Future<void> onDeleteAscentTap() async {
    if (isBusy) {
      return;
    }

    isDeletingAscent = true;
    errorMessage = null;
    _safeNotifyListeners();

    try {
      await _deleteAscentUseCase(ascent.id);

      if (_disposed) return;

      await _syncAfterAscentChange();

      if (_disposed) return;

      _feedback = AscentEditFeedback.deleted;
      _destination = AscentEditNavigationDestination.back;
    } on ApiException catch (error) {
      if (_disposed) return;

      errorMessage = error.message;
    } catch (_) {
      if (_disposed) return;

      errorMessage = 'No s\'ha pogut eliminar l\'ascensió';
    } finally {
      if (!_disposed) {
        isDeletingAscent = false;
        _safeNotifyListeners();
      }
    }
  }

  void onCancelTap() {
    if (isBusy) {
      return;
    }

    _destination = AscentEditNavigationDestination.back;
    _safeNotifyListeners();
  }

  void consumeNavigation() {
    _destination = AscentEditNavigationDestination.none;
  }

  void consumeFeedback() {
    _feedback = AscentEditFeedback.none;
  }

  bool _isValidForm() {
    final selectedDate = _selectedAscentDate;
    final today = DateUtils.dateOnly(DateTime.now());

    if (!isDateLocked && selectedDate != null && selectedDate.isAfter(today)) {
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

  // Aquest mètode refresca l’estat compartit després de modificar o eliminar una ascensió.
  // Permet que el catàleg, el mapa, el dashboard i les estadístiques reflecteixin el canvi.
  Future<void> _syncAfterAscentChange() async {
    try {
      final updatedStatus = await _getPeakStatusUseCase.execute(ascent.peakId);

      if (_disposed) {
        return;
      }

      _peakStatusStore.setStatus(updatedStatus);
    } catch (error) {
      debugPrint('[AscentEditController] Peak status refresh error: $error');
    } finally {
      _userStatsRefreshStore.notifyStatsChanged();
    }
  }

  AscentPhoto? _findPhotoById(int photoId) {
    for (final photo in photos) {
      if (photo.id == photoId) {
        return photo;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    notesController.dispose();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    final day = _twoDigits(date.day);
    final month = _twoDigits(date.month);
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}