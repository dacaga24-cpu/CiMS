import 'package:flutter/material.dart';

// Aquesta targeta agrupa les opcions principals del compte d’usuari.
// Rep les accions des de la pantalla per mantenir separada la part visual de la lògica.
class ProfileSettingsOptionsCard extends StatelessWidget {
  const ProfileSettingsOptionsCard({
    super.key,
    required this.onEditProfileTap,
    required this.onChangePasswordTap,
  });

  // Aquestes accions permeten obrir els formularis associats al perfil.
  // La targeta no decideix què passa, només comunica la interacció de l’usuari.
  final VoidCallback onEditProfileTap;
  final VoidCallback onChangePasswordTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileSettingsOptionTile(
            icon: Icons.person_outline,
            title: 'Dades personals',
            subtitle: 'Actualitza el teu nom i cognoms',
            onTap: onEditProfileTap,
          ),
          const Divider(height: 1),
          _ProfileSettingsOptionTile(
            icon: Icons.lock_outline,
            title: 'Canviar contrasenya',
            subtitle: 'Actualitza la contrasenya del compte',
            onTap: onChangePasswordTap,
          ),
        ],
      ),
    );
  }
}

// Aquest widget representa una opció individual dins de la targeta.
// Centralitza l’estil de cada fila perquè totes les opcions siguin coherents.
class _ProfileSettingsOptionTile extends StatelessWidget {
  const _ProfileSettingsOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF2E7D32)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
