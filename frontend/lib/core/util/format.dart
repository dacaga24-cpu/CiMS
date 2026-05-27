import 'package:intl/intl.dart';

// Aquest fitxer agrupa formats numèrics compartits per l’aplicació.
// Centralitza la presentació de valors perquè les pantalles mantinguin el mateix criteri.

const String _kAltitudeUnitShort = 'm';
const String _kAltitudeUnitLong = 'metres';

// Aquest formatador aplica el separador de milers segons el format català.
// Es reutilitza per evitar repetir la mateixa configuració en cada crida.
final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('ca');

// Aquesta funció formata una altitud en metres.
// Permet mostrar-la amb unitat curta o llarga segons el context visual.
String formatAltitude(int? meters, {bool longUnit = false}) {
  if (meters == null) return '';
  final unit = longUnit ? _kAltitudeUnitLong : _kAltitudeUnitShort;
  return '${_decimalFormatter.format(meters)} $unit';
}
