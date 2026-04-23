import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el resum del cim dins de la pantalla de registre.
// Serveix per recordar en tot moment sobre quin cim s’està registrant l’ascensió.
class AscentRegisterPeakSummary extends StatelessWidget {
  const AscentRegisterPeakSummary({
    super.key,
    required this.peak,
  });

  // Aquest cim aporta les dades bàsiques que es mostren a la capçalera
  // per donar context abans d’omplir el formulari.
  final Peak peak;

  @override
  Widget build(BuildContext context) {
    // Aquest bloc agrupa la informació essencial del cim
    // perquè l’usuari identifiqui ràpidament què està registrant.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          peak.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17212B),
          ),
        ),
        const SizedBox(height: 10),

        // Aquesta fila destaca l’altitud com una dada rellevant
        // per situar millor el cim dins del registre.
        Row(
          children: [
            const Icon(
              Icons.terrain_rounded,
              size: 18,
              color: Color(0xFF0B57D0),
            ),
            const SizedBox(width: 8),
            Text(
              '${peak.altitude} m',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B57D0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Aquest bloc mostra les comarques associades al cim.
        // Si no n’hi ha cap, es deixa un text alternatiu perquè
        // la informació territorial no quedi buida.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: peak.regions.isEmpty
              ? const [
                  _RegionChip(label: 'Sense comarca'),
                ]
              : peak.regions
                  .map(
                    (region) => _RegionChip(label: region.name),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

// Aquest petit widget intern pinta cada comarca com un element visual separat,
// fent que la informació territorial sigui més clara i fàcil de llegir.
class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
  });

  // Aquest text representa el nom de la comarca
  // que es vol mostrar dins del resum del cim.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0B57D0),
        ),
      ),
    );
  }
}