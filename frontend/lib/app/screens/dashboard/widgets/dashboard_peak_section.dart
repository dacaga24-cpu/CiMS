import 'package:cims/app/screens/dashboard/widgets/dashboard_peak_tile.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:flutter/material.dart';

// Aquesta secció agrupa una llista curta de cims dins del dashboard.
// S’utilitza tant per als cims pendents com per als cims favorits.
class DashboardPeakSection extends StatelessWidget {
  const DashboardPeakSection({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.peaks,
    required this.icon,
    required this.onPeakTap,
  });

  // Aquest bloc defineix el contingut i el comportament de la secció.
  // Permet reutilitzar el mateix component per mostrar diferents llistes de cims dins del dashboard.
  final String title;
  final String emptyMessage;
  final List<DashboardPeakItem> peaks;
  final IconData icon;
  final ValueChanged<int> onPeakTap;

  // Aquest mètode construeix la secció visual amb títol, icona i contingut.
  // Si no hi ha cims, mostra un missatge informatiu; si n’hi ha, crea una targeta per cada cim.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0B57D0), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2933),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (peaks.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...peaks.map(
              (peak) => DashboardPeakTile(
                peak: peak,
                onTap: () => onPeakTap(peak.id),
              ),
            ),
        ],
      ),
    );
  }
}