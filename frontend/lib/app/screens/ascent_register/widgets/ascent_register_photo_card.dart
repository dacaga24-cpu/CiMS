import 'dart:typed_data';

import 'package:flutter/material.dart';

// Aquest widget gestiona visualment les fotos opcionals d’una ascensió.
// Permet afegir diverses imatges, veure-les com a miniatures i eliminar-les abans de confirmar.
class AscentRegisterPhotoCard extends StatelessWidget {
  const AscentRegisterPhotoCard({
    super.key,
    required this.previewBytes,
    required this.isLoading,
    required this.canAddMorePhotos,
    required this.selectedPhotosCount,
    required this.maxPhotos,
    required this.onTap,
    required this.onRemoveTap,
    this.errorMessage,
  });

  // Aquestes imatges en memòria permeten mostrar les fotos ja preparades pel frontend.
  final List<Uint8List> previewBytes;

  // Aquest estat indica si alguna foto s’està preparant o pujant.
  final bool isLoading;

  // Aquest valor indica si encara es poden afegir més fotos.
  final bool canAddMorePhotos;

  // Aquest comptador mostra quantes fotos s’han seleccionat.
  final int selectedPhotosCount;

  // Aquest límit evita superar el màxim de fotos permès per ascensió.
  final int maxPhotos;

  // Aquesta acció obre el selector d’imatges.
  final VoidCallback onTap;

  // Aquesta acció elimina una foto concreta del formulari.
  final ValueChanged<int> onRemoveTap;

  // Aquest missatge mostra possibles errors durant la selecció o pujada de fotos.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = previewBytes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 190),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              if (hasPhotos)
                _PhotoThumbnailsGrid(
                  previewBytes: previewBytes,
                  canAddMorePhotos: canAddMorePhotos,
                  onAddTap: onTap,
                  onRemoveTap: onRemoveTap,
                )
              else
                _EmptyPhotoState(
                  isLoading: isLoading,
                  onTap: onTap,
                ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: BorderRadius.circular(20),
                    ),
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
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$selectedPhotosCount/$maxPhotos fotos seleccionades',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667085),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 6),
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

// Aquest bloc mostra les fotos seleccionades en format de miniatura.
// També afegeix una targeta final per continuar pujant imatges si encara hi ha espai.
class _PhotoThumbnailsGrid extends StatelessWidget {
  const _PhotoThumbnailsGrid({
    required this.previewBytes,
    required this.canAddMorePhotos,
    required this.onAddTap,
    required this.onRemoveTap,
  });

  final List<Uint8List> previewBytes;
  final bool canAddMorePhotos;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < previewBytes.length; index++)
          _PhotoThumbnail(
            bytes: previewBytes[index],
            onRemoveTap: () => onRemoveTap(index),
          ),
        if (canAddMorePhotos)
          _AddMorePhotoTile(
            onTap: onAddTap,
          ),
      ],
    );
  }
}

// Aquesta miniatura representa una foto seleccionada.
// Inclou un botó per eliminar-la abans de confirmar el registre.
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.bytes,
    required this.onRemoveTap,
  });

  final Uint8List bytes;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            bytes,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: _RemovePhotoButton(
            onTap: onRemoveTap,
          ),
        ),
      ],
    );
  }
}

// Aquest estat mostra el contingut inicial quan encara no hi ha cap foto seleccionada.
class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isLoading ? null : onTap,
        child: const SizedBox(
          height: 170,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 42,
                  color: Color(0xFF0B57D0),
                ),
                SizedBox(height: 14),
                Text(
                  'Selecciona imatges',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Aquesta targeta permet afegir més fotos quan ja n’hi ha alguna seleccionada.
class _AddMorePhotoTile extends StatelessWidget {
  const _AddMorePhotoTile({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const SizedBox(
          width: 92,
          height: 92,
          child: Center(
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 30,
              color: Color(0xFF0B57D0),
            ),
          ),
        ),
      ),
    );
  }
}

// Aquest botó permet treure una foto seleccionada sense sortir del formulari.
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
          width: 26,
          height: 26,
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}