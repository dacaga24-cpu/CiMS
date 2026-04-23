import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget construeix la capçalera principal del detall del cim.
// Mostra un bloc visual destacat amb el nom, l’altitud i la zona del cim.
class PeakDetailHeader extends StatelessWidget {
  const PeakDetailHeader({
    super.key,
    required this.peak,
  });

  // Aquesta propietat rep el cim que s’està mostrant
  // i permet pintar la informació principal del seu detall.
  final Peak peak;

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
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8CD2D9),
            Color(0xFF4CA0C7),
            Color(0xFF1D669E),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F5B8A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 250,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                child: const Text(
                  'Últim ascens: 12/05/2024', // TODO: Substituir per data real del backend
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24465D),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Aquest bloc actua com a placeholder mentre el projecte
            // no disposa d’imatges reals dels cims.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.landscape_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Imatge pendent',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Aquest bloc mostra la ubicació general i les dades principals del cim,
            // prioritzant una lectura clara del nom i de l’altitud.
            Text(
              regionsText.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Colors.white70,
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${peak.altitude} metres',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}