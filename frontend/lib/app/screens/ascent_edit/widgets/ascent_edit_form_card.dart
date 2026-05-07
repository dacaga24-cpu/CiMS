import 'package:cims/app/screens/ascent_edit/ascent_edit_controller.dart';
import 'package:cims/app/widgets/forms/app_form_card.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa el formulari principal de la pantalla d’edició.
// Manté la pantalla lleugera i concentra els camps visuals de l’ascensió.
class AscentEditFormCard extends StatelessWidget {
  const AscentEditFormCard({
    super.key,
    required this.controller,
    required this.onDateTap,
  });

  // Aquest controller aporta l’estat actual del formulari,
  // incloent la data, les notes i les fotos ja carregades de l’ascensió.
  final AscentEditController controller;

  // Aquesta acció permet obrir el selector de data
  // des del mateix bloc del formulari.
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Data de l\'ascens'),
          const SizedBox(height: 10),
          _DateSelectorField(
            value: controller.formattedAscentDate,
            onTap: onDateTap,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Notes i experiència'),
          const SizedBox(height: 10),
          _NotesField(
            controller: controller.notesController,
            onChanged: controller.onNotesChanged,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Fotos de l\'ascensió'),
          const SizedBox(height: 10),
          _AscentEditPhotosSection(
            photos: controller.photos,
            isLoading: controller.isLoadingPhotos,
            errorMessage: controller.photosErrorMessage,
            onRetryTap: controller.onRetryPhotosTap,
          ),
        ],
      ),
    );
  }
}

// Aquest text s’utilitza com a capçalera visual de cada bloc del formulari.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Color(0xFF667085),
      ),
    );
  }
}

// Aquest camp visual mostra la data actual de l’ascensió
// i obre el calendari quan l’usuari el toca.
class _DateSelectorField extends StatelessWidget {
  const _DateSelectorField({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Color(0xFF98A2B3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF344054),
                  ),
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Aquest camp recull les notes de l’ascensió.
// En edició ja apareix inicialitzat amb les notes guardades anteriorment.
class _NotesField extends StatelessWidget {
  const _NotesField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.multiline,
        minLines: 5,
        maxLines: 7,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText:
              'Com ha anat la pujada? Temps invertit, condicions meteorològiques, sensacions...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFFB0B3B8),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// Aquest bloc mostra les fotos ja associades a l’ascensió.
// Permet veure les imatges guardades sense barrejar la càrrega amb la resta del formulari.
class _AscentEditPhotosSection extends StatelessWidget {
  const _AscentEditPhotosSection({
    required this.photos,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryTap,
  });

  final List<AscentPhoto> photos;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE84A4A),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetryTap,
              child: const Text('Torna-ho a provar'),
            ),
          ],
        ),
      );
    }

    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aquesta ascensió no té fotos associades.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final photo in photos)
          _AscentEditPhotoThumbnail(
            photo: photo,
          ),
      ],
    );
  }
}

// Aquesta miniatura representa una foto existent de l’ascensió.
// Utilitza la URL temporal retornada pel backend per mostrar la imatge.
class _AscentEditPhotoThumbnail extends StatelessWidget {
  const _AscentEditPhotoThumbnail({
    required this.photo,
  });

  final AscentPhoto photo;

  @override
  Widget build(BuildContext context) {
    final downloadUrl = photo.downloadUrl;

    if (downloadUrl == null) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: const Color(0xFFE4E7EC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF667085),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        downloadUrl,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 92,
            height: 92,
            color: const Color(0xFFE4E7EC),
            child: const Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF667085),
            ),
          );
        },
      ),
    );
  }
}