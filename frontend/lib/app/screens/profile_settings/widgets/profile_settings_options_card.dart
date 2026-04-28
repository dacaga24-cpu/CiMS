import 'package:flutter/material.dart';
import 'profile_settings_option_tile.dart';

// Aquest contenidor agrupa les opcions principals de perfil.
// En aquest sprint poden quedar visuals, excepte el logout.
class ProfileSettingsOptionsCard extends StatelessWidget {
  const ProfileSettingsOptionsCard({super.key});

  // Aquest mètode construeix la targeta d’opcions del compte.
  // Agrupa accions relacionades amb el perfil perquè la pantalla sigui més clara i ordenada.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          ProfileSettingsOptionTile(
            icon: Icons.person_outline_rounded,
            title: 'Dades personals',
          ),
          SizedBox(height: 2),
          ProfileSettingsOptionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Canviar contrasenya',
          ),
          SizedBox(height: 2),
          ProfileSettingsOptionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Eliminar compte',
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}
