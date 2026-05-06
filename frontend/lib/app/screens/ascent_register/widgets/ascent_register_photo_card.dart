import 'dart:typed_data';

import 'package:flutter/material.dart';

// Aquest widget gestiona visualment la foto opcional d’una ascensió.
// Permet seleccionar una imatge, veure’n la previsualització i eliminar-la abans de confirmar.
class AscentRegisterPhotoCard extends StatelessWidget {
  const AscentRegisterPhotoCard({
    super.key,
    required this.previewBytes,
    required this.isLoading,
    required this.onTap,
    required this.onRemoveTap,
    this.errorMessage,
  });

  // Aquesta imatge en memòria permet mostrar la foto ja preparada pel frontend.
  final Uint8List? previewBytes;

  // Aquest estat indica si la foto s’està preparant o pujant.
  final bool isLoading;

  // Aquesta acció obre el selector d’imatge.
  final VoidCallback onTap;

  // Aquesta acció elimina la foto seleccionada del formulari.
  final VoidCallback onRemoveTap;

  // Aquest missatge mostra possibles errors durant la selecció o pujada de la foto.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final imageBytes = previewBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: isLoading ? null : onTap,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 170),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: [
                  if (imageBytes != null)
                    Positioned.fill(
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const _EmptyPhotoState(),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0x66000000),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (imageBytes != null && !isLoading)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _RemovePhotoButton(
                        onTap: onRemoveTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE84A4A),
            ),
          ),
        ],
      ],
    );
  }
}

// Aquest estat mostra el contingut inicial quan encara no hi ha cap foto seleccionada.
class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 32,
            color: Color(0xFF0B57D0),
          ),
          SizedBox(height: 12),
          Text(
            'Selecciona una imatge',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest botó permet treure la foto seleccionada sense sortir del formulari.
class _RemovePhotoButton extends StatelessWidget {
  const _RemovePhotoButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xDD000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
