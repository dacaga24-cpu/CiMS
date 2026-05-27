// Aquest fitxer agrupa utilitats senzilles per donar format a textos.
// S’utilitza per mostrar noms de manera coherent a la interfície.

String capitalizeFirst(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final first = trimmed.substring(0, 1).toUpperCase();
  final rest = trimmed.substring(1).toLowerCase();
  return '$first$rest';
}

// Aquesta funció aplica el format de majúscula inicial a cada paraula.
// És útil per mostrar noms i cognoms compostos de manera uniforme.
String capitalizeWords(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  return trimmed.split(RegExp(r'\s+')).map(capitalizeFirst).join(' ');
}
