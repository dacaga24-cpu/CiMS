import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget representa la targeta reutilitzable de cada cim del catàleg.
// Mostra només la informació essencial d’aquesta iteració: nom, altitud i regions.
class PeakDetailCard extends StatelessWidget {
  const PeakDetailCard({
    super.key,
    required this.peak,
    this.onTap,
  });

  // Aquest bloc rep les dades del cim que s’han de mostrar
  // i l’acció opcional que s’executarà quan l’usuari seleccioni la targeta.
  final Peak peak;
  final VoidCallback? onTap;

  // Aquest mètode construeix la targeta visual d’un cim dins del catàleg.
  // La targeta resumeix la informació principal i deixa preparada la interacció
  // per accedir més endavant al detall complet del cim.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          child: Row(
            children: [
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
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const TextSpan(text: '  '),
                          TextSpan(
                            text: '${peak.altitude} m',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B57D0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

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
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Aquest element lateral reforça visualment que la targeta
              // es pot seleccionar per accedir a més informació.
              Container(
                width: 42,
                height: 42,
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