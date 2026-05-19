import 'package:flutter/material.dart';

// Aquest full d’accions agrupa les opcions disponibles per gestionar la foto de perfil.
// Permet separar la part visual de les accions reals, que es resolen des de la pantalla.
class ProfilePhotoActionsSheet extends StatelessWidget {
  const ProfilePhotoActionsSheet({
    super.key,
    required this.hasProfilePhoto,
    required this.isUpdatingProfilePhoto,
    required this.onSelectPhotoTap,
    required this.onDeletePhotoTap,
  });

  final bool hasProfilePhoto;
  final bool isUpdatingProfilePhoto;
  final Future<void> Function() onSelectPhotoTap;
  final Future<void> Function() onDeletePhotoTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Foto de perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              enabled: !isUpdatingProfilePhoto,
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text(
                'Seleccionar nova foto',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await onSelectPhotoTap();
              },
            ),
            if (hasProfilePhoto) ...[
              const Divider(height: 1),
              ListTile(
                enabled: !isUpdatingProfilePhoto,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD84C4C),
                ),
                title: const Text(
                  'Eliminar foto actual',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD84C4C),
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await onDeletePhotoTap();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
