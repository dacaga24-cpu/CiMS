import 'package:cims/app/widgets/weather/weather_visuals.dart';
import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra la secció de filtres meteorològics dins del
// panell de filtres del catàleg i del mapa. L'usuari pot triar un dia
// dins de l'horitzó disponible (avui o fins a 9 dies endavant) i
// seleccionar una o més condicions; el filtre només té efecte quan
// totes dues parts estan informades.

// Aquest sostre coincideix amb el rang d'horitzó de la Google Weather
// API (10 dies, dia 0 = avui inclòs). Si en algun moment el contracte
// del backend canvia, només cal actualitzar aquesta constant.
const int _maxFutureDays = 9;

class PeaksWeatherFilterSection extends StatelessWidget {
  const PeaksWeatherFilterSection({
    super.key,
    required this.selectedDate,
    required this.selectedConditions,
    required this.onDateChanged,
    required this.onConditionToggled,
  });

  // Data ISO YYYY-MM-DD seleccionada o null si l'usuari encara no n'ha
  // triat cap. La UI distingeix visualment "sense triar" de "avui" amb
  // un placeholder explícit.
  final String? selectedDate;

  // Conjunt de condicions normalitzades seleccionades. Pot ser buit
  // mentre l'usuari encara està configurant el panell.
  final Set<WeatherConditionType> selectedConditions;

  // Acció disparada quan l'usuari escull una nova data.
  final ValueChanged<String?> onDateChanged;

  // Acció disparada quan l'usuari toca un chip de condició. Es
  // notifica la condició concreta perquè el panell pugui afegir-la o
  // treure-la del conjunt sense haver de calcular l'estat aquí.
  final ValueChanged<WeatherConditionType> onConditionToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meteorologia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17212B),
          ),
        ),
        const SizedBox(height: 12),
        _DateRow(
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectableConditions
              .map((condition) => _ConditionChip(
                    condition: condition,
                    isSelected: selectedConditions.contains(condition),
                    onTap: () => onConditionToggled(condition),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // Es presenten les cinc condicions normalitzades que el backend
  // exposa. UNKNOWN no es mostra perquè és un valor intern usat només
  // quan Google retorna un codi que encara no està al mapa.
  static const List<WeatherConditionType> _selectableConditions = [
    WeatherConditionType.sunny,
    WeatherConditionType.cloudy,
    WeatherConditionType.rainy,
    WeatherConditionType.snowy,
    WeatherConditionType.foggy,
  ];
}

// Aquest widget mostra el selector de dia. Reuneix l'etiqueta amb el
// dia actualment triat i obre un date picker quan es prem; el rang
// queda fixat a [avui, avui+9] perquè el backend rebutja qualsevol
// data fora de l'horitzó de previsió.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final String? selectedDate;
  final ValueChanged<String?> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(selectedDate);
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: selectedDate == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF17212B),
                ),
              ),
            ),
            if (selectedDate != null)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 18,
                ),
                onPressed: () => onDateChanged(null),
                tooltip: 'Treure la data',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = selectedDate != null
        ? (DateTime.tryParse(selectedDate!) ?? today)
        : today;
    // Encara no es passa locale: 'ca' a showDatePicker perquè el
    // projecte no té configurat flutter_localizations a MaterialApp.
    // Sense aquests delegates, forçar el locale faria caure el
    // calendari a anglès en lloc del sistema. Quan s'afegeixi
    // localització global, n'hi haurà prou amb afegir aquí
    // `locale: const Locale('ca')`. Els helpText/cancelText/confirmText
    // ja viatgen en català explícitament.
    final picked = await showDatePicker(
      context: context,
      initialDate: _clampWithinRange(initial, today),
      firstDate: today,
      lastDate: today.add(const Duration(days: _maxFutureDays)),
      helpText: 'Tria un dia',
      cancelText: 'Cancel·lar',
      confirmText: 'Triar',
    );
    if (picked == null) return;
    onDateChanged(_formatIso(picked));
  }

  // Si la data persisida queda fora del rang vàlid (perquè ha passat el
  // dia que es va triar, per exemple), s'inicialitza al primer dia
  // possible per evitar que showDatePicker tiri d'assert.
  DateTime _clampWithinRange(DateTime value, DateTime today) {
    final lastDay = today.add(const Duration(days: _maxFutureDays));
    if (value.isBefore(today)) return today;
    if (value.isAfter(lastDay)) return lastDay;
    return value;
  }

  String _formatIso(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  // Aquest mètode tradueix la data persisida a una etiqueta natural en
  // català: "Avui", "Demà" o el nom del dia amb el dia del mes.
  String _labelFor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tria un dia';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = normalized.difference(today).inDays;
    if (diff == 0) return 'Avui';
    if (diff == 1) return 'Demà';
    const labels = [
      'Dilluns',
      'Dimarts',
      'Dimecres',
      'Dijous',
      'Divendres',
      'Dissabte',
      'Diumenge',
    ];
    final index = parsed.weekday - 1;
    final dayName = (index >= 0 && index < labels.length) ? labels[index] : '';
    return '$dayName ${parsed.day}';
  }
}

// Aquest chip representa una condició meteorològica seleccionable.
// Reaprofita les icones i el color d'accent del helper compartit perquè
// la paleta sigui idèntica a la que pinta la card del detall del cim.
class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.condition,
    required this.isSelected,
    required this.onTap,
  });

  final WeatherConditionType condition;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = weatherAccentColorFor(condition);
    final borderColor = isSelected ? accent : const Color(0xFFE5E7EB);
    final backgroundColor = isSelected
        ? accent.withValues(alpha: 0.14)
        : const Color(0xFFF8FAFC);
    final labelColor =
        isSelected ? accent : const Color(0xFF4B5563);

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            weatherIconFor(condition),
            size: 16,
            color: labelColor,
          ),
          const SizedBox(width: 6),
          Text(condition.displayLabel),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: backgroundColor,
      backgroundColor: backgroundColor,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: borderColor),
    );
  }
}
