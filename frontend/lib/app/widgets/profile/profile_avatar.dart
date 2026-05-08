import 'package:flutter/material.dart';

// Aquest widget mostra la imatge de perfil de l’usuari.
// Si encara no hi ha cap foto associada, mostra una icona genèrica
// per mantenir una representació visual coherent del compte.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    this.profilePhotoUrl,
    this.onTap,
    this.backgroundColor = const Color(0xFF0B57D0),
    this.iconColor = Colors.white,
    this.iconSize,
  });

  final double size;
  final String? profilePhotoUrl;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double? iconSize;

  // Aquest mètode construeix un avatar circular reutilitzable.
  // Serveix tant per a la pantalla de perfil com per a la capçalera principal.
  @override
  Widget build(BuildContext context) {
    final imageUrl = profilePhotoUrl;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: imageUrl == null || imageUrl.isEmpty
                ? ColoredBox(
                    color: backgroundColor,
                    child: Icon(
                      Icons.person_rounded,
                      color: iconColor,
                      size: iconSize ?? size * 0.55,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return ColoredBox(
                        color: backgroundColor,
                        child: Icon(
                          Icons.person_rounded,
                          color: iconColor,
                          size: iconSize ?? size * 0.55,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}