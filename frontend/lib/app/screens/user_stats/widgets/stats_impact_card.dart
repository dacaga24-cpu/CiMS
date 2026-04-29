import 'package:cims/core/entity/user_stats.dart';
import 'package:flutter/material.dart';

// Aquesta targeta mostra l’impacte general de l’usuari.
// Inclou el total d’ascensions i una representació visual simple de l’evolució mensual.
class StatsImpactCard extends StatelessWidget {
  const StatsImpactCard({
    super.key,
    required this.totalAscents,
    required this.monthlyAscents,
  });

  // Aquestes dades permeten mostrar el volum total d’activitat i l’evolució mensual.
  // S’utilitzen per donar una visió ràpida del progrés acumulat de l’usuari.
  final int totalAscents;
  final List<MonthlyAscentsStats> monthlyAscents;

  // Aquest mètode construeix la targeta principal d’impacte amb el total d’ascensions
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
            'EL TEU IMPACTE',
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

  // Aquest getter limita el gràfic als últims set mesos disponibles.
  // Si encara no hi ha dades mensuals, mostra una estructura neutra.
  List<int> get _visibleValues {
    if (monthlyAscents.isEmpty) {
      return const [1, 2, 2, 3, 4, 5, 4];
    }

    final totals = monthlyAscents.map((month) => month.total).toList();

    if (totals.length <= 7) {
      return totals;
    }

    return totals.sublist(totals.length - 7);
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
    final height = 24 + (52 * (value / maxValue));

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
