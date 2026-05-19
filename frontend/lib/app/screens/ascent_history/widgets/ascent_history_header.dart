import 'package:cims/core/util/format.dart';
import 'package:flutter/material.dart';

// Aquesta capçalera mostra la informació principal del cim seleccionat.
// El bloc superior reserva l’espai on en el futur es podrà mostrar una fotografia real del cim.
class AscentHistoryHeader extends StatelessWidget {
  const AscentHistoryHeader({
    super.key,
    required this.peakName,
    required this.altitude,
    required this.regions,
    required this.totalAscents,
  });

  // Aquestes dades defineixen el contingut principal de la capçalera:
  // nom del cim, territori, altitud i nombre total d’ascensions registrades.
  final String peakName;
  final int altitude;
  final List<String> regions;
  final int totalAscents;

  // Aquest mètode construeix la targeta superior amb placeholder d’imatge
  // i una etiqueta inferior amb el total d’ascensions del cim.
  @override
  Widget build(BuildContext context) {
    final regionsText = regions.isEmpty ? 'Catalunya' : regions.join(', ');

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: double.infinity,
          height: 142,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: const DecorationImage(
              image: AssetImage('assets/images/montana_0001.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(157, 255, 255, 255),
                BlendMode.srcATop,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                peakName.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                regionsText.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatAltitude(altitude),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -17,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0F5ADB),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330F5ADB),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 6),
                Text(
                  'ASCENSIONS TOTALS: $totalAscents',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
