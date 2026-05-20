// Aquest fitxer concentra utilitats senzilles de manipulació de cadenes
// per a presentació. Mantenim aquests helpers separats dels formats
// numèrics (`format.dart`) perquè no comparteixen dependències i així
// queda més clar on tocar quan cal afegir-ne de nous.

// Retorna la cadena amb la primera lletra en majúscula i la resta en
// minúscules ("Title Case" per a una sola paraula). Pensat per pintar
// noms d'usuari de manera coherent independentment de com els hagi
// guardat l'usuari (`MARC`, `marc`, `MaRc` ... → `Marc`).
//
// La normalització només s'aplica en presentació; el valor guardat al
// backend no es toca, així evitem perdre la grafia original que pugui
// tenir significat (per exemple "de la Vall").
String capitalizeFirst(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final first = trimmed.substring(0, 1).toUpperCase();
  final rest = trimmed.substring(1).toLowerCase();
  return '$first$rest';
}

// Versió per a noms complets amb múltiples paraules separades per
// espais. Aplica `capitalizeFirst` a cada paraula. Útil per cognoms
// compostos del tipus "garcia ferrer" → "Garcia Ferrer".
String capitalizeWords(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  return trimmed.split(RegExp(r'\s+')).map(capitalizeFirst).join(' ');
}
