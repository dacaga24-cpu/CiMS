import 'package:cims/app/widgets/branding/cims_logo.dart';
import 'package:flutter/material.dart';

// Aquest bloc mostra el logotip de CiMS i el nom de l’usuari
// com a elements centrals de la pantalla.
class ProfileSettingsHeader extends StatelessWidget {
  const ProfileSettingsHeader({
    super.key,
    required this.displayName,
  });

  // Nom que es mostra a la capçalera del perfil.
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Aquest contenidor dona protagonisme visual a la part superior
        // i fa de suport per al logotip o futura imatge de perfil.
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: CimsLogo(
              width: 68,
              height: 68,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D1D1F),
            height: 1,
          ),
        ),
      ],
    );
  }
}
