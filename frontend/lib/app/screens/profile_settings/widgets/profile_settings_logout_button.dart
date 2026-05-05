import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:flutter/material.dart';

// Aquest botó és l’acció funcional principal de la pantalla en aquest sprint.
class ProfileSettingsLogoutButton extends StatelessWidget {
  const ProfileSettingsLogoutButton({
    super.key,
    required this.isLoggingOut,
    required this.onLogoutTap,
  });

  // Indica si el tancament de sessió està en curs.
  // Mentre està carregant, el botó queda desactivat i mostra un text de procés.
  final bool isLoggingOut;
  final VoidCallback onLogoutTap;

  // Aquest mètode construeix el botó de tancament de sessió.
  // Utilitza el botó secundari reutilitzable per mantenir coherència visual amb la resta de l’app.
  @override
  Widget build(BuildContext context) {
    return SecondaryPillButton(
      label: isLoggingOut ? 'Tancant sessió...' : 'Tancar sessió',
      enabled: !isLoggingOut,
      onPressed: onLogoutTap,
    );
  }
}
