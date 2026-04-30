import 'package:cims/core/entity/user_stats.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra l’historial recent d’ascensions de l’usuari.
// Inclou el total acumulat i una representació visual configurable de l’evolució mensual.
class StatsHistoryCard extends StatelessWidget {
  const StatsHistoryCard({
    super.key,
    required this.totalAscents,
    required this.monthlyAscents,
    this.monthsToShow = 6,
  }) : assert(
          monthsToShow == 1 ||
              monthsToShow == 3 ||
              monthsToShow == 6 ||
              monthsToShow == 12,
        );

  // Aquestes dades permeten mostrar el volum total d’activitat i l’evolució mensual.
  // El nombre de mesos visibles es pot ajustar segons el nivell de detall necessari.
  final int totalAscents;
  final List<MonthlyAscentsStats> monthlyAscents;
  final int monthsToShow;

  // Aquest mètode construeix la targeta d’historial amb el total d’ascensions
  // i un gràfic senzill que ajuda a interpretar l’activitat recent.
  @override
  Widget build(BuildContext context) {
    final values = _visibleValues;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HISTORIAL',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F5ADB),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalAscents.toString(),
                style: const TextStyle(
                  fontSize: 34,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF161616),
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'Ascensions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF242424),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Últims $monthsToShow mesos',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Aquest bloc genera les barres del gràfic mensual a partir de les dades visibles.
          // Les últimes barres es destaquen per facilitar la lectura de l’activitat recent.
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < values.length; index++) ...[
                  Expanded(
                    child: _StatsBar(
                      value: values[index],
                      maxValue: _maxValue(values),
                      highlighted: index >= values.length - 3,
                    ),
                  ),
                  if (index != values.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Aquest getter limita el gràfic al nombre de mesos configurat.
  // Si hi ha menys dades disponibles, completa el principi amb mesos sense activitat.
  List<int> get _visibleValues {
    final totals = monthlyAscents.map((month) => month.total).toList();

    if (totals.isEmpty) {
      return List.filled(monthsToShow, 0);
    }

    final visibleTotals = totals.length <= monthsToShow
        ? totals
        : totals.sublist(totals.length - monthsToShow);

    if (visibleTotals.length == monthsToShow) {
      return visibleTotals;
    }

    return [
      ...List.filled(monthsToShow - visibleTotals.length, 0),
      ...visibleTotals,
    ];
  }

  // Aquest mètode obté el valor més alt del gràfic.
  // Serveix per calcular l’alçada proporcional de cada barra sense generar divisions insegures.
  int _maxValue(List<int> values) {
    if (values.isEmpty) return 1;

    final max = values.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }
}

// Aquest widget representa una barra individual del gràfic.
// El color canvia en els últims mesos per remarcar l’activitat més recent.
class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.value,
    required this.maxValue,
    required this.highlighted,
  });

  // Aquestes dades defineixen la mida i l’estat visual de cada barra.
  // Permeten comparar cada mes amb el valor màxim del període mostrat.
  final int value;
  final int maxValue;
  final bool highlighted;

  // Aquest mètode construeix una barra proporcional al valor mensual rebut.
  @override
  Widget build(BuildContext context) {
    final height = value == 0 ? 18.0 : 24 + (52 * (value / maxValue));

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: height,
        decoration: BoxDecoration(
          color:
              highlighted ? const Color(0xFF0F5ADB) : const Color(0xFFDDE5F2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
