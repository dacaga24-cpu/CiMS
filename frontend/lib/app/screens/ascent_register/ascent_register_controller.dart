import 'package:flutter/material.dart';

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
  pendingSave,
}

// Aquest controller gestiona l’estat local del formulari de registre d’ascensió.
// En aquesta iteració només controla presentació, validació mínima i navegació,
// sense connectar encara amb cap cas d’ús ni amb el backend.
class AscentRegisterController extends ChangeNotifier {
  AscentRegisterController({
    DateTime? initialDate,
  }) : _selectedAscentDate = DateUtils.dateOnly(initialDate ?? DateTime.now());

  // Aquest camp guarda el text lliure que l’usuari escriu
  // per deixar observacions sobre l’ascensió.
  final TextEditingController notesController = TextEditingController();

  // Aquest bloc manté l’estat intern mínim del formulari:
  // la data seleccionada, el control del cicle de vida i
  // els avisos que la vista ha d’interpretar.
  DateTime _selectedAscentDate;
  bool _disposed = false;

  AscentRegisterNavigationDestination _destination =
      AscentRegisterNavigationDestination.none;
  AscentRegisterFeedback _feedback = AscentRegisterFeedback.none;

  DateTime get selectedAscentDate => _selectedAscentDate;

  // Aquest valor preparat permet mostrar la data del formulari
  // en un format clar i directe per a l’usuari.
  String get formattedAscentDate => _formatDate(_selectedAscentDate);

  AscentRegisterNavigationDestination get destination => _destination;

  AscentRegisterFeedback get feedback => _feedback;

  // Aquest mètode actualitza la data seleccionada del registre.
  // La pantalla li passa la data escollida des del selector de calendari.
  void onAscentDateChanged(DateTime value) {
    _selectedAscentDate = DateUtils.dateOnly(value);
    _safeNotifyListeners();
  }

  // Aquest mètode deixa preparat el futur enviament del formulari.
  // De moment només informa que el desat real encara no està connectat.
  void onConfirmTap() {
    _feedback = AscentRegisterFeedback.pendingSave;
    _safeNotifyListeners();
  }

  // Aquest mètode indica a la vista que l’usuari vol sortir del formulari.
  void onCancelTap() {
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