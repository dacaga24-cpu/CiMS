import 'package:cims/core/entity/user_stats.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra l’historial recent d’ascensions de l’usuari.
// Inclou el total acumulat i una representació visual dels últims mesos.
class StatsHistoryCard extends StatelessWidget {
  const StatsHistoryCard({
    super.key,
    required this.totalAscents,
    required this.monthlyAscents,
    this.monthsToShow = 12,
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
    final months = _visibleMonths;
    final maxValue = _maxValue(months);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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
            'HISTORIAL D’ASCENSIONS',
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
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < months.length; index++) ...[
                  Expanded(
                    child: _StatsMonthBar(
                      month: months[index],
                      maxValue: maxValue,
                      highlighted: index >= months.length - 3,
                    ),
                  ),
                  if (index != months.length - 1) const SizedBox(width: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Aquest getter limita el gràfic al nombre de mesos configurat.
  // Si no hi ha dades suficients, completa el principi amb mesos sense activitat.
  List<MonthlyAscentsStats> get _visibleMonths {
    final sortedMonths = monthlyAscents
        .where((month) => month.month.isNotEmpty)
        .toList();

    if (sortedMonths.isEmpty) {
      return _emptyRecentMonths();
    }

    final visibleMonths = sortedMonths.length <= monthsToShow
        ? sortedMonths
        : sortedMonths.sublist(sortedMonths.length - monthsToShow);

    if (visibleMonths.length == monthsToShow) {
      return visibleMonths;
    }

    return [
      ..._missingPreviousMonths(
        visibleMonths.first.month,
        monthsToShow - visibleMonths.length,
      ),
      ...visibleMonths,
    ];
  }

  // Aquest mètode crea mesos buits quan encara no hi ha historial disponible.
  // Això permet mantenir el gràfic estable visualment.
  List<MonthlyAscentsStats> _emptyRecentMonths() {
    final now = DateTime.now();
    final months = <MonthlyAscentsStats>[];

    for (var index = monthsToShow - 1; index >= 0; index--) {
      final date = DateTime(now.year, now.month - index);
      months.add(
        MonthlyAscentsStats(
          month: _formatMonth(date.year, date.month),
          total: 0,
        ),
      );
    }

    return months;
  }

  // Aquest mètode genera els mesos previs que falten abans del primer mes rebut.
  // S’utilitza quan el backend retorna menys mesos dels que la targeta ha de mostrar.
  List<MonthlyAscentsStats> _missingPreviousMonths(
    String firstMonth,
    int count,
  ) {
    final parsedDate = _parseMonth(firstMonth);
    if (parsedDate == null || count <= 0) {
      return const [];
    }

    final months = <MonthlyAscentsStats>[];

    for (var index = count; index >= 1; index--) {
      final date = DateTime(parsedDate.year, parsedDate.month - index);
      months.add(
        MonthlyAscentsStats(
          month: _formatMonth(date.year, date.month),
          total: 0,
        ),
      );
    }

    return months;
  }

  // Aquest mètode obté el valor més alt del gràfic.
  // Serveix per calcular l’alçada proporcional de cada barra.
  int _maxValue(List<MonthlyAscentsStats> months) {
    if (months.isEmpty) return 1;

    final values = months.map((month) => month.total).toList();
    final max = values.reduce((a, b) => a > b ? a : b);

    return max == 0 ? 1 : max;
  }

  // Aquest mètode transforma una etiqueta "YYYY-MM" en una data simple.
  DateTime? _parseMonth(String value) {
    if (value.length < 7) return null;

    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(5, 7));

    if (year == null || month == null) {
      return null;
    }

    return DateTime(year, month);
  }

  // Aquest mètode genera una etiqueta mensual normalitzada en format "YYYY-MM".
  String _formatMonth(int year, int month) {
    final date = DateTime(year, month);
    final label = date.month.toString().padLeft(2, '0');

    return '${date.year}-$label';
  }
}

// Aquest widget representa una barra mensual del gràfic.
// Mostra el número d’ascensions dins de la barra i el mes sota la barra.
class _StatsMonthBar extends StatelessWidget {
  const _StatsMonthBar({
    required this.month,
    required this.maxValue,
    required this.highlighted,
  });

  // Aquestes dades defineixen el valor mensual, l’escala del gràfic
  // i si la barra forma part del tram més recent.
  final MonthlyAscentsStats month;
  final int maxValue;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final value = month.total;
    final barHeight = value == 0 ? 24.0 : 30 + (54 * (value / maxValue));

    final barColor =
        highlighted ? const Color(0xFF0F5ADB) : const Color(0xFFDDE5F2);

    final textColor =
        highlighted ? Colors.white : const Color(0xFF344054);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: barHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          month.shortMonthLabel,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}