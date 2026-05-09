import 'package:cims/core/entity/ascent.dart';
import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/usecase/ascents/update_ascent_usecase.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/usecase/ascents/get_ascent_photos_usecase.dart';
import 'package:flutter/material.dart';

// Aquest límit coincideix amb la validació del backend.
// Evita guardar notes massa llargues i permet mostrar un error abans d’enviar canvis.
const int _maxNotesLength = 2000;

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
}

// Aquest controller gestiona l’estat local de l’edició d’una ascensió.
// Rep una ascensió existent i prepara el formulari amb la data opcional,
// les notes i les fotos ja registrades.
class AscentEditController extends ChangeNotifier {
  AscentEditController({
    required this.ascent,
    UpdateAscentUseCase? updateAscentUseCase,
    GetAscentPhotosUseCase? getAscentPhotosUseCase,
  })  : _selectedAscentDate = ascent.ascentDate == null
            ? null
            : DateUtils.dateOnly(ascent.ascentDate!),
        notesController = TextEditingController(text: ascent.notes ?? ''),
        _updateAscentUseCase =
            updateAscentUseCase ?? UpdateAscentUseCase(ApiClientImpl()),
        _getAscentPhotosUseCase =
            getAscentPhotosUseCase ?? GetAscentPhotosUseCase(ApiClientImpl());

  // Aquesta ascensió és el registre original que l’usuari vol consultar o editar.
  final Ascent ascent;

  // Aquest camp guarda les notes de l’ascensió i ja ve inicialitzat
  // amb el text que l’usuari havia registrat anteriorment.
  final TextEditingController notesController;

  // Aquest cas d’ús permet guardar els canvis de l’ascensió al backend.
  final UpdateAscentUseCase _updateAscentUseCase;

  // Aquest cas d’ús permet carregar les fotos ja associades a l’ascensió.
  final GetAscentPhotosUseCase _getAscentPhotosUseCase;

  // Aquest bloc manté l’estat intern del formulari:
  // data opcional, càrrega, errors, navegació i avisos puntuals.
  DateTime? _selectedAscentDate;
  bool _disposed = false;

  bool isLoading = false;
  bool showValidation = false;
  String? errorMessage;

  AscentEditNavigationDestination _destination =
      AscentEditNavigationDestination.none;
  AscentEditFeedback _feedback = AscentEditFeedback.none;

  DateTime? get selectedAscentDate => _selectedAscentDate;

  // Aquest bloc guarda l’estat de les fotos existents de l’ascensió.
  List<AscentPhoto> photos = const [];
  bool isLoadingPhotos = false;
  String? photosErrorMessage;

  // Aquest valor indica si actualment hi ha una data seleccionada.
  // Permet a la pantalla mostrar o ocultar l’acció de netejar-la.
  bool get hasSelectedAscentDate => _selectedAscentDate != null;

  // Aquest valor preparat mostra la data seleccionada o un text d’ajuda
  // quan l’ascensió no té cap data associada.
  String get formattedAscentDate {
    final selectedDate = _selectedAscentDate;

    if (selectedDate == null) {
      return 'Seleccionar data';
    }

    return _formatDate(selectedDate);
  }

  AscentEditNavigationDestination get destination => _destination;

  AscentEditFeedback get feedback => _feedback;

  // Aquest getter indica si les notes superen el límit acceptat.
  // La pantalla el pot utilitzar per mostrar l’error visual corresponent.
  bool get hasInvalidNotes =>
      showValidation && notesController.text.length > _maxNotesLength;

  // Aquest getter indica si l’usuari ha modificat alguna dada del formulari.
  bool get hasChanges {
    final originalDate = ascent.ascentDate == null
        ? null
        : DateUtils.dateOnly(ascent.ascentDate!);
    final originalNotes = (ascent.notes ?? '').trim();
    final currentNotes = notesController.text.trim();

    final hasDateChanged = originalDate == null
        ? _selectedAscentDate != null
        : _selectedAscentDate == null ||
            !_selectedAscentDate!.isAtSameMomentAs(originalDate);

    return hasDateChanged || currentNotes != originalNotes;
  }

  // Aquest mètode carrega les dades complementàries de l’edició.
  // Ara mateix recupera les fotos existents de l’ascensió.
  Future<void> initialize() async {
    await _loadPhotos();
  }

  // Aquest mètode recupera les fotos associades a l’ascensió des del backend.
  // Si falla, manté la pantalla operativa i mostra un missatge només al bloc de fotos.
  Future<void> _loadPhotos() async {
    isLoadingPhotos = true;
    photosErrorMessage = null;
    _safeNotifyListeners();

    try {
      final loadedPhotos = await _getAscentPhotosUseCase(ascent.id);

      if (_disposed) {
        return;
      }

      photos = loadedPhotos;
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      photos = const [];
      photosErrorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      photos = const [];
      photosErrorMessage = 'No s\'han pogut carregar les fotos';
    } finally {
      if (!_disposed) {
        isLoadingPhotos = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode permet repetir la càrrega de fotos si hi ha hagut un error.
  Future<void> onRetryPhotosTap() {
    return _loadPhotos();
  }

  // Aquest getter retorna les notes netes, o null si l’usuari deixa el camp buit.
  String? get normalizedNotes {
    final notes = notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }

  // Aquest mètode actualitza la data seleccionada de l’ascensió.
  // La pantalla li passa la data escollida des del selector de calendari.
  void onAscentDateChanged(DateTime value) {
    if (isLoading) {
      return;
    }

    _selectedAscentDate = DateUtils.dateOnly(value);
    errorMessage = null;
    _safeNotifyListeners();
  }

  // Aquest mètode deixa l’ascensió sense data.
  // Serveix per als casos en què l’usuari no vol conservar cap dia concret
  // associat al registre.
  void onClearAscentDateTap() {
    if (isLoading) {
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

  // Aquest mètode valida el formulari i envia els canvis al backend.
  // Si l’actualització funciona, avisa la pantalla i torna a l’historial.
  Future<void> onSaveTap() async {
    if (isLoading) {
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
        notes: normalizedNotes,
      );

      if (_disposed) {
        return;
      }

      _feedback = AscentEditFeedback.saved;
      _destination = AscentEditNavigationDestination.back;
    } on ApiException catch (error) {
      if (_disposed) {
        return;
      }

      errorMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }

      errorMessage = 'No s’ha pogut actualitzar l’ascensió';
    } finally {
      if (!_disposed) {
        isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  // Aquest mètode indica a la vista que l’usuari vol sortir de l’edició.
  void onCancelTap() {
    if (isLoading) {
      return;
    }

    _destination = AscentEditNavigationDestination.back;
    _safeNotifyListeners();
  }

  // Aquest mètode reinicia l’acció de navegació després que la vista l’hagi resolt.
  void consumeNavigation() {
    _destination = AscentEditNavigationDestination.none;
  }

  // Aquest mètode reinicia l’avís puntual després que la vista ja l’hagi mostrat.
  void consumeFeedback() {
    _feedback = AscentEditFeedback.none;
  }

  // Aquest mètode valida les dades abans de guardar els canvis.
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