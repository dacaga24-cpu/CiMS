import 'dart:async';

// Aquest helper retarda l’execució d’una cerca mentre l’usuari escriu.
// S’utilitza per evitar consultes repetides al backend en catàleg i mapa.
class PeaksSearchDebouncer {
  Timer? _timer;

  // Aquest mètode programa una cerca amb un petit retard.
  // Si arriba un nou text abans d’executar-se, cancel·la la cerca anterior.
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

  // Aquest mètode cancel·la qualsevol cerca pendent.
  // Evita executar accions quan el controller o la pantalla ja s’han tancat.
  void dispose() {
    _timer?.cancel();
  }
}