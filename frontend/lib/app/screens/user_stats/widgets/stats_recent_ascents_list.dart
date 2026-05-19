import 'package:cims/core/entity/user_stats.dart';
import 'package:cims/core/util/format.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra les últimes ascensions de l’usuari.
// Cada element resumeix el cim, la data, la comarca i l’altitud.
class StatsRecentAscentsList extends StatelessWidget {
  const StatsRecentAscentsList({
    super.key,
    required this.ascents,
    required this.onAscentTap,
  });

  // Aquesta llista conté les ascensions més recents ja preparades pel backend.
  // Permet construir el resum visual de l’activitat recent de l’usuari.
  final List<RecentAscentStats> ascents;

  // Aquesta acció s’executa quan l’usuari selecciona una ascensió recent.
  // La pantalla d’estadístiques la fa servir per navegar cap a l’historial del cim.
  final ValueChanged<RecentAscentStats> onAscentTap;

  // Aquest mètode construeix el llistat d’ascensions recents o un estat buit
  // quan l’usuari encara no ha registrat cap activitat recent.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimes ascensions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF181818),
          ),
        ),
        const SizedBox(height: 14),
        if (ascents.isEmpty)
          const _EmptyRecentAscentsCard()
        else
          for (var index = 0; index < ascents.length; index++) ...[
            _RecentAscentTile(
              ascent: ascents[index],
              onTap: () {
                onAscentTap(ascents[index]);
              },
            ),
            if (index != ascents.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }
}

// Aquest widget representa una ascensió concreta dins del llistat recent.
class _RecentAscentTile extends StatelessWidget {
  const _RecentAscentTile({
    required this.ascent,
    required this.onTap,
  });

  // Aquesta dada conté la informació resumida d’una ascensió.
  // S’utilitza per mostrar el cim, la data, les regions i l’altitud dins d’una targeta.
  final RecentAscentStats ascent;

  // Aquesta acció obre l’historial del cim associat a l’ascensió seleccionada.
  final VoidCallback onTap;

  // Aquest mètode construeix la targeta visual d’una ascensió recent.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F3F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.terrain_rounded,
                  color: Color(0xFF0F5ADB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Aquest bloc mostra la informació principal del cim ascendit.
              // Limita el text per mantenir estable el disseny encara que el nom sigui llarg.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ascent.peakName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF161616),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(ascent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF737B88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Aquest bloc mostra la data de l’ascensió i una etiqueta visual
              // que reforça que l’activitat correspon a un cim completat.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(ascent.ascentDate),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Aquest mètode prepara el subtítol de l’ascensió combinant territori i altitud.
  // Si el cim no té regions associades, mostra només l’altitud.
  String _buildSubtitle(RecentAscentStats ascent) {
    final altitude = formatAltitude(ascent.altitude);

    if (ascent.regions.isEmpty) {
      return altitude;
    }

    return '${ascent.formattedRegions} · $altitude';
  }

  // Aquest mètode transforma la data en un format curt i llegible per al llistat.
  String _formatDate(DateTime date) {
    const months = [
      'Gen',
      'Feb',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Oct',
      'Nov',
      'Des',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];

    return '$day $month';
  }
}

// Aquest widget mostra un estat buit quan encara no hi ha ascensions recents.
class _EmptyRecentAscentsCard extends StatelessWidget {
  const _EmptyRecentAscentsCard();

  // Aquest mètode construeix una targeta informativa perquè la pantalla no quedi buida.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Text(
        'Encara no hi ha ascensions recents.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF737B88),
        ),
      ),
    );
  }
}
