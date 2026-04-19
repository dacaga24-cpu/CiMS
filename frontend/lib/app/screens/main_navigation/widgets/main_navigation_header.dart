import 'package:flutter/material.dart';

// Aquesta capçalera forma part de la navegació principal compartida.
// Mostra l’accés al perfil i delega l’acció de navegació a la pantalla pare.
class MainNavigationHeader extends StatelessWidget {
  const MainNavigationHeader({
    super.key,
    required this.onProfileTap,
  });

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B6CFF),
                    Color(0xFF0E63F4),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}