import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/register_ascent_usecase.dart';
import 'package:flutter/material.dart';

// Aquest límit coincideix amb la validació del backend.
// Evita enviar notes massa llargues i permet mostrar un error abans de fer la petició.
const int _maxNotesLength = 2000;

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
  })  : _selectedAscentDate = DateUtils.dateOnly(initialDate ?? DateTime.now()),
        _registerAscentUseCase = registerAscentUseCase ??
            RegisterAscentUseCase(
              ApiClientImpl(),
            ),
        _peakStatusStore = peakStatusStore ?? AppSession.peakStatusStore,
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore;

  // Aquest identificador indica a quin cim quedarà associada l’ascensió.
  // Arriba des de la pantalla de detall del cim.
  final int peakId;

  // Aquest bloc agrupa les dependències que permeten registrar l’ascensió,
  // mantenir sincronitzat l’estat compartit dels cims i avisar les estadístiques.
  final RegisterAscentUseCase _registerAscentUseCase;
  final PeakStatusStore _peakStatusStore;
  final UserStatsRefreshStore _userStatsRefreshStore;

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

  // Aquest mètode actualitza la data seleccionada del registre.
  // La pantalla li passa la data escollida des del selector de calendari.
  void onAscentDateChanged(DateTime value) {
    if (isLoading) {
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

  // Aquest mètode confirma el formulari i envia l’ascensió al backend.
  // Si el registre funciona, també marca el cim com a completat i avisa
  // que les estadístiques s’han de tornar a carregar.
  Future<void> onConfirmTap() async {
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
      await _registerAscentUseCase(
        peakId: peakId,
        ascentDate: _selectedAscentDate,
        notes: _normalizedNotes,
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
    if (isLoading) {
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
