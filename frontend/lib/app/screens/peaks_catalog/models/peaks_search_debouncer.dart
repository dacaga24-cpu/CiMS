import 'dart:async';

// Aquest helper aplica una petita espera abans d’executar una cerca.
// Es comparteix entre el catàleg i el mapa per evitar duplicar el mateix Timer.
class PeaksSearchDebouncer {
  Timer? _timer;

  // Programa una cerca amb el text rebut.
  // Si l’usuari continua escrivint, la cerca anterior es cancel·la.
  void run(
    String value,
    Future<void> Function(String? search) onSearch,
  ) {
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 350),
      () {
        final trimmedValue = value.trim();
        onSearch(trimmedValue.isEmpty ? null : trimmedValue);
      },
    );
  }

  // Cancel·la qualsevol cerca pendent.
  void dispose() {
    _timer?.cancel();
  }
}
