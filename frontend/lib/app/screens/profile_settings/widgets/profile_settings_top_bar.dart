import 'package:flutter/material.dart';

// Aquesta capçalera manté el patró visual net de la referència,
// amb una única acció de tornar enrere.
class ProfileSettingsTopBar extends StatelessWidget {
  const ProfileSettingsTopBar({
    super.key,
    required this.onBackTap,
  });

  // Acció que s’executa quan l’usuari vol tornar a la pantalla anterior.
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onBackTap,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF2F66FF),
        ),
      ),
    );
  }
}
