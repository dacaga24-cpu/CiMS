import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget reserva la zona del mapa del cim.
// Ara mateix prepara la targeta visual i l’acció futura per obrir la seva posició.
class PeakDetailMapCard extends StatelessWidget {
  const PeakDetailMapCard({
    super.key,
    required this.peak,
    required this.onTap,
  });

  // Aquestes propietats reben la informació del cim i l’acció
  // que s’executarà quan l’usuari vulgui obrir-ne la ubicació.
  final Peak peak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Aquest text prepara la informació de coordenades que es mostra a la targeta.
    // Si el cim encara no té posició disponible, s’informa clarament a l’usuari.
    final coordinatesText = peak.hasMapPosition
        ? 'Lat ${peak.latitude!.toStringAsFixed(5)} · Lon ${peak.longitude!.toStringAsFixed(5)}'
        : 'La posició del cim encara no està disponible en aquesta iteració.'; //TODO: Reemplaçar aquest missatge quan es conegui el motiu de la falta de coordenades (ex. dades pendents, cim no geolocalitzable, etc.).

    // Aquest bloc construeix la targeta de localització del cim.
    // La seva funció és reservar l’espai del mapa dins del detall
    // i oferir un punt clar d’accés a la ubicació quan estigui disponible.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aquest fragment mostra un espai visual provisional del mapa
            // mentre aquesta part encara no s’ha substituït per una vista real.
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8EEF5),
                    Color(0xFFD9E2EC),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.map_outlined,
                      size: 44,
                      color: Color(0xFF5D6C80),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vista de mapa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Aquest bloc resumeix la informació de localització
            // i activa el botó només si el cim ja disposa de coordenades.
            const Text(
              'Ubicació del cim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17212B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coordinatesText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF5B6573),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: peak.hasMapPosition ? onTap : null,
              icon: const Icon(Icons.open_in_full_rounded),
              label: const Text('Veure al mapa'),
            ),
          ],
        ),
      ),
    );
  }
}