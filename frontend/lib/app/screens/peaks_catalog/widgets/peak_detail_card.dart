import 'package:cims/app/screens/peaks_catalog/widgets/peaks_status_tags.dart';
import 'package:cims/app/widgets/peaks/peak_circular_thumbnail.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:flutter/material.dart';

// Aquest widget representa la targeta reutilitzable de cada cim del catàleg.
// Mostra la informació essencial del cim, una miniatura visual i,
// si existeixen, els seus estats personals.
class PeakDetailCard extends StatelessWidget {
  const PeakDetailCard({
    super.key,
    required this.peak,
    this.status,
    this.onTap,
  });

  // Aquest bloc rep les dades del cim, el seu estat personal opcional
  // i l’acció que s’executarà quan l’usuari seleccioni la targeta.
  final Peak peak;
  final PeakStatus? status;
  final VoidCallback? onTap;

  // Aquest mètode construeix la targeta visual del cim dins del catàleg.
  // Combina les dades bàsiques del cim amb una miniatura i els estats personals.
  @override
  Widget build(BuildContext context) {
    final currentStatus = status;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Aquesta miniatura dona una referència visual ràpida del cim.
              // De moment utilitza una imatge comuna per a totes les muntanyes.
              const PeakCircularThumbnail(
                size: 62,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aquest bloc destaca el nom del cim i la seva altitud
                    // com a informació principal de cada element del llistat.
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: peak.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const TextSpan(text: '  '),
                          TextSpan(
                            text: '${peak.altitude} m',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B57D0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Aquest bloc mostra la ubicació territorial del cim.
                    // Això permet identificar ràpidament a quina regió o regions pertany.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF9AA3B2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            peak.formattedRegions,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7B8596),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Aquest bloc mostra només els estats personals actius.
                    // No es mostra cap informació si el cim no té estats assignats.
                    if (currentStatus != null && currentStatus.hasAnyStatus) ...[
                      const SizedBox(height: 12),
                      PeakStatusTags(
                        status: currentStatus,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Aquest element lateral reforça visualment que la targeta
              // es pot seleccionar per accedir a més informació.
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F3F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9EA6B4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}