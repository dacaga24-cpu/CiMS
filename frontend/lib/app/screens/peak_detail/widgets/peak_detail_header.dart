import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget construeix la capçalera principal del detall del cim.
// Mostra un bloc visual destacat amb el nom, l’altitud, la zona del cim
// i, si existeix, la data de l’última ascensió registrada per l’usuari.
class PeakDetailHeader extends StatelessWidget {
  const PeakDetailHeader({
    super.key,
    required this.peak,
    this.lastAscentDate,
  });

  // Aquesta propietat rep el cim que s’està mostrant
  // i permet pintar la informació principal del seu detall.
  final Peak peak;

  // Aquesta propietat rep la data de l’última ascensió de l’usuari.
  // Si no hi ha cap ascensió registrada, la capçalera no mostra aquest indicador.
  final DateTime? lastAscentDate;

  @override
  Widget build(BuildContext context) {
    // Aquest text prepara la zona o comarques del cim per mostrar-les
    // dins la capçalera. Si encara no n’hi ha informació, es mostra un valor general.
    final regionsText =
        peak.formattedRegions.isEmpty ? 'CATALUNYA' : peak.formattedRegions;

    // Aquest bloc construeix la part visual més destacada de la pantalla de detall.
    // Resumeix d’un cop d’ull la informació principal del cim i actua com a entrada
    // visual al contingut de la resta de la pàgina.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/montana_0001.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastAscentDate != null) ...[
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Últim ascens: ${_formatDate(lastAscentDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF24465D),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Aquest bloc mostra la ubicació general i les dades principals del cim
// sobre un fons clar per garantir una lectura correcta damunt la imatge.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    regionsText.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Color(0xFF24465D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    peak.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 0.95,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${peak.altitude} metres',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Aquest mètode transforma la data de l’última ascensió
  // en un format curt i clar per mostrar-la a la capçalera.
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}
