import 'package:cims/app/widgets/peaks/peak_circular_thumbnail.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/util/format.dart';
import 'package:flutter/material.dart';

// Aquest element representa un cim dins d’una secció del dashboard.
// Mostra una miniatura reutilitzable i la informació mínima necessària
// perquè l’usuari pugui identificar-lo ràpidament.
class DashboardPeakTile extends StatelessWidget {
  const DashboardPeakTile({
    super.key,
    required this.peak,
    required this.onTap,
  });

  // Aquestes dades defineixen el cim que es mostrarà i l’acció que s’executarà en seleccionar-lo.
  // Permeten reutilitzar l’element en diferents llistes del dashboard.
  final DashboardPeakItem peak;
  final VoidCallback onTap;

  // Aquest mètode construeix l’element visual del cim amb miniatura,
  // nom, dades complementàries i accés interactiu cap al detall.
  @override
  Widget build(BuildContext context) {
    final details = [
      if (peak.regionName != null) peak.regionName!,
      if (peak.altitude != null) formatAltitude(peak.altitude),
      if (peak.ascentCount != null) '${peak.ascentCount} ascensions',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            // Aquesta miniatura manté la mateixa representació visual dels cims
            // que ja s’utilitza al catàleg i al detall ràpid del mapa.
            PeakCircularThumbnail(
              size: 48,
              imageUrl: peak.imageUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peak.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
