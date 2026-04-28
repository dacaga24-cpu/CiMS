import 'package:flutter/material.dart';

// Aquest botó és l’acció funcional principal de la pantalla en aquest sprint.
class ProfileSettingsLogoutButton extends StatelessWidget {
  const ProfileSettingsLogoutButton({
    super.key,
    required this.isLoggingOut,
    required this.onLogoutTap,
  });

  // Indica si el tancament de sessió està en curs.
  // Mentre està carregant, el botó queda desactivat i mostra un indicador.
  final bool isLoggingOut;
  final VoidCallback onLogoutTap;

  // Aquest mètode construeix el botó de tancament de sessió.
  // Adapta el seu estat visual perquè l’usuari vegi quan l’acció està en procés.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton.icon(
        onPressed: isLoggingOut ? null : onLogoutTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFF0CACA),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: Colors.transparent,
        ),
        // Aquest bloc adapta el contingut del botó segons l’estat actual,
        // mostrant càrrega mentre s’està tancant la sessió.
        icon: isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD84C4C),
                size: 20,
              ),
        label: const Text(
          'Tancar sessió',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD84C4C),
          ),
        ),
      ),
    );
  }
}
