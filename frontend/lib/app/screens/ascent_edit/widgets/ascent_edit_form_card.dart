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
    required this.onPhotoTap,
    required this.onDeletePhotoTap,
  });

  // Aquest controller aporta l’estat actual del formulari,
  // incloent la data, les notes i les fotos ja carregades de l’ascensió.
  final AscentEditController controller;

  // Aquesta acció permet obrir el selector de data
  // des del mateix bloc del formulari.
  final VoidCallback onDateTap;

  // Aquesta acció permet obrir una foto existent en gran.
  final ValueChanged<AscentPhoto> onPhotoTap;

  // Aquesta acció demana a la pantalla que confirmi l’eliminació d’una foto.
  final ValueChanged<AscentPhoto> onDeletePhotoTap;

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
            hasValue: controller.hasSelectedAscentDate,
            onTap: onDateTap,
            onClearTap: controller.onClearAscentDateTap,
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
            deletingPhotoId: controller.deletingPhotoId,
            onRetryTap: controller.onRetryPhotosTap,
            onPhotoTap: onPhotoTap,
            onDeletePhotoTap: onDeletePhotoTap,
          ),
        ],
      ),
    );
  }
}

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

// Aquest camp mostra la data seleccionada o permet deixar-la buida.
// Això manté coherent l’edició amb els registres d’ascensió sense data.
class _DateSelectorField extends StatelessWidget {
  const _DateSelectorField({
    required this.value,
    required this.hasValue,
    required this.onTap,
    required this.onClearTap,
  });

  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback onClearTap;

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
          padding: const EdgeInsets.only(
            left: 18,
            right: 8,
          ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: hasValue
                        ? const Color(0xFF344054)
                        : const Color(0xFF98A2B3),
                  ),
                ),
              ),
              if (hasValue)
                IconButton(
                  onPressed: onClearTap,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF98A2B3),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: Color(0xFF98A2B3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
// Les imatges es mostren com a miniatures per mantenir el formulari compacte.
// En tocar una foto, la pantalla pot obrir-la en gran.
class _AscentEditPhotosSection extends StatelessWidget {
  const _AscentEditPhotosSection({
    required this.photos,
    required this.isLoading,
    required this.errorMessage,
    required this.deletingPhotoId,
    required this.onRetryTap,
    required this.onPhotoTap,
    required this.onDeletePhotoTap,
  });

  final List<AscentPhoto> photos;
  final bool isLoading;
  final String? errorMessage;
  final int? deletingPhotoId;
  final Future<void> Function() onRetryTap;
  final ValueChanged<AscentPhoto> onPhotoTap;
  final ValueChanged<AscentPhoto> onDeletePhotoTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 112,
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
        constraints: const BoxConstraints(minHeight: 112),
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
      children: photos.map((photo) {
        return _AscentEditPhotoCard(
          photo: photo,
          isDeleting: deletingPhotoId == photo.id,
          onTap: () => onPhotoTap(photo),
          onDeleteTap: () => onDeletePhotoTap(photo),
        );
      }).toList(),
    );
  }
}

// Aquesta miniatura representa una foto existent de l’ascensió.
// Permet obrir-la en gran o eliminar-la sense ocupar massa espai dins del formulari.
class _AscentEditPhotoCard extends StatelessWidget {
  const _AscentEditPhotoCard({
    required this.photo,
    required this.isDeleting,
    required this.onTap,
    required this.onDeleteTap,
  });

  final AscentPhoto photo;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final downloadUrl = photo.downloadUrl;

    return SizedBox(
      width: 92,
      height: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Material(
              color: const Color(0xFFE4E7EC),
              child: InkWell(
                onTap: downloadUrl == null || isDeleting ? null : onTap,
                child: downloadUrl == null
                    ? const Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFF667085),
                      )
                    : Image.network(
                        downloadUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF667085),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: Material(
                color: const Color(0xCC000000),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isDeleting ? null : onDeleteTap,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Center(
                      child: isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (photo.isPrimary)
              Positioned(
                left: 5,
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC18B56A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}