import 'package:cims/app/widgets/branding/cims_logo.dart';
import 'package:flutter/material.dart';

// Aquest bloc mostra el logotip de CiMS, el nom de l’usuari
// i el correu associat al compte com a informació principal del perfil.
class ProfileSettingsHeader extends StatelessWidget {
  const ProfileSettingsHeader({
    super.key,
    required this.displayName,
    required this.displayEmail,
  });

  // Nom que es mostra a la capçalera del perfil.
  final String displayName;

  // Correu del compte autenticat que ajuda a identificar la sessió actual.
  final String displayEmail;

  // Aquest mètode construeix la capçalera visual del perfil.
  // Mostra el logotip, el nom de l’usuari i el correu del compte.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        if (displayEmail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            displayEmail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
