import 'package:flutter/material.dart';

// Aquesta targeta agrupa les opcions principals del compte d’usuari.
// Rep les accions des de la pantalla per mantenir separada la part visual de la lògica.
class ProfileSettingsOptionsCard extends StatelessWidget {
  const ProfileSettingsOptionsCard({
    super.key,
    required this.onChangeProfilePhotoTap,
    required this.onEditProfileTap,
    required this.onChangePasswordTap,
    required this.onDeleteAccountTap,
  });

  // Aquestes accions permeten obrir els formularis associats al perfil.
  // La targeta no decideix què passa, només comunica la interacció de l’usuari.
  final VoidCallback onChangeProfilePhotoTap;
  final VoidCallback onEditProfileTap;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onDeleteAccountTap;

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
            title: 'Canviar foto de perfil',
            onTap: onChangeProfilePhotoTap,
          ),
          const Divider(height: 1),
          _ProfileSettingsOptionTile(
            title: 'Dades personals',
            onTap: onEditProfileTap,
          ),
          const Divider(height: 1),
          _ProfileSettingsOptionTile(
            title: 'Canviar contrasenya',
            onTap: onChangePasswordTap,
          ),
          const Divider(height: 1),
          _ProfileSettingsOptionTile(
            title: 'Desactivar compte',
            onTap: onDeleteAccountTap,
            isDestructive: true,
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
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? const Color(0xFFD84C4C) : const Color(0xFF0047C7);

    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDestructive ? color : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}