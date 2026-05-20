import 'package:cims/core/util/format.dart';
import 'package:flutter/material.dart';

// Aquesta capçalera mostra la informació principal del cim seleccionat
// dins de l'historial d'ascensions. Reutilitza el mateix tractament
// visual que la capçalera del detall del cim (mateix tipografia,
// caixa blanca que s'adapta al text i imatge de muntanya com a fons)
// per mantenir una experiència consistent quan l'usuari salta entre
// les dues pantalles.
class AscentHistoryHeader extends StatelessWidget {
  const AscentHistoryHeader({
    super.key,
    required this.peakName,
    required this.altitude,
    required this.regions,
    required this.totalAscents,
    this.imageUrl,
  });

  // Aquestes dades defineixen el contingut principal de la capçalera:
  // nom del cim, territori, altitud, nombre total d’ascensions i imatge associada.
  final String peakName;
  final int altitude;
  final List<String> regions;
  final int totalAscents;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final regionsText = regions.isEmpty ? 'CATALUNYA' : regions.join(', ');
    final trimmedImageUrl = imageUrl?.trim();

    final ImageProvider<Object> headerImageProvider;

    if (trimmedImageUrl == null || trimmedImageUrl.isEmpty) {
      headerImageProvider = const AssetImage('assets/images/montana_0001.png');
    } else {
      headerImageProvider = NetworkImage(trimmedImageUrl);
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: DecorationImage(
              image: headerImageProvider,
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      peakName,
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
                      formatAltitude(altitude, longUnit: true),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Aquest comptador es manté com a element distintiu de l'historial:
        // resumeix de cop d'ull quantes ascensions té el cim. Es posiciona
        // a sobre del límit inferior de la imatge perquè destaqui sense
        // ocupar espai dins la capçalera principal.
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
