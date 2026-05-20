import 'package:cims/app/widgets/profile/profile_avatar.dart';
import 'package:flutter/material.dart';

// Aquesta capçalera forma part de la navegació principal compartida.
// Mostra l’accés al perfil i delega l’acció de navegació a la pantalla pare.
class MainNavigationHeader extends StatelessWidget {
  const MainNavigationHeader({
    super.key,
    required this.onProfileTap,
    this.profilePhotoUrl,
  });

  final VoidCallback onProfileTap;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        // Semantics + Tooltip per fer evident que aquest avatar és el botó
        // d'accés al perfil. Abans no tenia cap label exposat al lector de
        // pantalla i tampoc no donava cap pista visual del seu propòsit.
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
