import 'package:cims/app/widgets/profile/profile_avatar.dart';
import 'package:flutter/material.dart';

// Aquesta capçalera forma part de la navegació principal.
// Mostra l’accés al perfil i delega l’acció a la pantalla pare.
class MainNavigationHeader extends StatelessWidget {
  const MainNavigationHeader({
    super.key,
    required this.onProfileTap,
    this.profilePhotoUrl,
  });

  // Aquestes dades defineixen l’acció del perfil i la imatge que s’ha de mostrar.
  final VoidCallback onProfileTap;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Semantics(
          label: 'Perfil i configuració',
          button: true,
          child: Tooltip(
            message: 'Perfil',
            child: ProfileAvatar(
              size: 44,
              profilePhotoUrl: profilePhotoUrl,
              onTap: onProfileTap,
              backgroundColor: const Color(0xFF0B57D0),
              iconColor: Colors.white,
              iconSize: 24,
            ),
          ),
        ),
      ],
    );
  }
}