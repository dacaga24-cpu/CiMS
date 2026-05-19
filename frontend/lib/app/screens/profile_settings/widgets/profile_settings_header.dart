import 'package:cims/app/widgets/profile/profile_avatar.dart';
import 'package:flutter/material.dart';

// Aquest bloc mostra la imatge de perfil, el nom de l’usuari
// i el correu associat al compte com a informació principal del perfil.
class ProfileSettingsHeader extends StatelessWidget {
  const ProfileSettingsHeader({
    super.key,
    required this.displayName,
    required this.displayEmail,
    this.profilePhotoUrl,
    this.isUpdatingProfilePhoto = false,
  });

  // Nom que es mostra a la capçalera del perfil.
  final String displayName;

  // Correu del compte autenticat que ajuda a identificar la sessió actual.
  final String displayEmail;

  // URL de la foto de perfil de l’usuari, si ja en té una associada.
  final String? profilePhotoUrl;

  // Indica si la foto de perfil s’està actualitzant.
  // Permet mostrar una capa de càrrega mentre finalitza la pujada.
  final bool isUpdatingProfilePhoto;

  // Aquest mètode construeix la capçalera visual del perfil.
  // Mostra la foto de l’usuari si existeix i manté una icona genèrica si no n’hi ha cap.
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              ProfileAvatar(
                size: 112,
                profilePhotoUrl: profilePhotoUrl,
                backgroundColor: Colors.white,
                iconColor: const Color(0xFF0B57D0),
                iconSize: 58,
              ),
              if (isUpdatingProfilePhoto)
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
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