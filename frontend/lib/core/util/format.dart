import 'package:intl/intl.dart';

// Aquest fitxer concentra els formats numèrics compartits per tota
// l'aplicació, evitant duplicar lògica entre pantalles.
//
// Important: requereix que `intl` estigui inicialitzat amb dades de
// localització (`flutter_localizations` ja s'encarrega de fer-ho via
// `MaterialApp.localizationsDelegates`).

const String _kAltitudeUnitShort = 'm';
const String _kAltitudeUnitLong = 'metres';

// Formatador estàtic per evitar reconstruir el `NumberFormat` a cada
// crida. La convenció catalana fa servir el punt com a separador
// de milers.
final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('ca');

// Formata una altitud en metres amb separador de milers.
//
// - `meters`: l'altitud a representar. Si és `null`, retorna cadena buida.
// - `longUnit`: si és `true`, utilitza "metres" enlloc de "m". Pensat
//   per a títols destacats (ex. capçalera del detall de cim).
String formatAltitude(int? meters, {bool longUnit = false}) {
  if (meters == null) return '';
  final unit = longUnit ? _kAltitudeUnitLong : _kAltitudeUnitShort;
  return '${_decimalFormatter.format(meters)} $unit';
}
