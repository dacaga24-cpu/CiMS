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
            isLocked: controller.isDateLocked,
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
            isUploading: controller.isUploadingPhotos,
            canAddMorePhotos: controller.canAddMorePhotos,
            maxPhotos: controller.maxAscentPhotos,
            errorMessage: controller.photosErrorMessage,
            deletingPhotoId: controller.deletingPhotoId,
            onRetryTap: controller.onRetryPhotosTap,
            onAddPhotosTap: controller.onAddPhotosTap,
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

// Aquest camp mostra la data seleccionada de l’ascensió.
// Si la data prové d’una verificació, queda bloquejada perquè representa el moment real de captura.
class _DateSelectorField extends StatelessWidget {
  const _DateSelectorField({
    required this.value,
    required this.hasValue,
    required this.isLocked,
    required this.onTap,
    required this.onClearTap,
  });

  final String value;
  final bool hasValue;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback onClearTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isLocked
        ? const Color(0xFF667085)
        : hasValue
            ? const Color(0xFF344054)
            : const Color(0xFF98A2B3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isLocked ? const Color(0xFFEDEFF3) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isLocked ? null : onTap,
            child: Container(
              height: 56,
              padding: const EdgeInsets.only(
                left: 18,
                right: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : Icons.calendar_today_outlined,
                    size: 20,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  if (hasValue && !isLocked)
                    IconButton(
                      onPressed: onClearTap,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF98A2B3),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        isLocked
                            ? Icons.verified_rounded
                            : Icons.expand_more_rounded,
                        color: foregroundColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isLocked) ...[
          const SizedBox(height: 8),
          const Text(
            'Data bloquejada per verificació geolocalitzada.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ],
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

// Aquest bloc mostra i gestiona les fotos associades a l’ascensió.
// Manté el mateix comportament funcional que el registre: estat buit clicable,
// miniatures existents i tile d’afegir mentre no s’ha arribat al límit.
class _AscentEditPhotosSection extends StatelessWidget {
  const _AscentEditPhotosSection({
    required this.photos,
    required this.isLoading,
    required this.isUploading,
    required this.canAddMorePhotos,
    required this.maxPhotos,
    required this.errorMessage,
    required this.deletingPhotoId,
    required this.onRetryTap,
    required this.onAddPhotosTap,
    required this.onPhotoTap,
    required this.onDeletePhotoTap,
  });

  final List<AscentPhoto> photos;
  final bool isLoading;
  final bool isUploading;
  final bool canAddMorePhotos;
  final int maxPhotos;
  final String? errorMessage;
  final int? deletingPhotoId;
  final Future<void> Function() onRetryTap;
  final Future<void> Function() onAddPhotosTap;
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
          ),
          if (photos.isNotEmpty || canAddMorePhotos) ...[
            const SizedBox(height: 12),
            _PhotosWrap(
              photos: photos,
              isUploading: isUploading,
              canAddMorePhotos: canAddMorePhotos,
              deletingPhotoId: deletingPhotoId,
              onAddPhotosTap: onAddPhotosTap,
              onPhotoTap: onPhotoTap,
              onDeletePhotoTap: onDeletePhotoTap,
            ),
          ],
        ],
      );
    }

    if (photos.isEmpty) {
      return _EmptyPhotosPicker(
        isUploading: isUploading,
        canAddMorePhotos: canAddMorePhotos,
        maxPhotos: maxPhotos,
        onTap: onAddPhotosTap,
      );
    }

    return _PhotosWrap(
      photos: photos,
      isUploading: isUploading,
      canAddMorePhotos: canAddMorePhotos,
      deletingPhotoId: deletingPhotoId,
      onAddPhotosTap: onAddPhotosTap,
      onPhotoTap: onPhotoTap,
      onDeletePhotoTap: onDeletePhotoTap,
    );
  }
}

// Aquest estat buit permet afegir fotos directament quan l’ascensió encara no en té.
// Evita mostrar només un missatge informatiu i manté el mateix flux que el registre.
class _EmptyPhotosPicker extends StatelessWidget {
  const _EmptyPhotosPicker({
    required this.isUploading,
    required this.canAddMorePhotos,
    required this.maxPhotos,
    required this.onTap,
  });

  final bool isUploading;
  final bool canAddMorePhotos;
  final int maxPhotos;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = canAddMorePhotos && !isUploading;

    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: isUploading
                ? const _UploadingIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F0FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF0B57D0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Selecciona imatges',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pots afegir fins a $maxPhotos fotos per ascensió.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
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

// Aquest contenidor mostra les miniatures existents i, si encara es pot,
// una tile final per afegir més fotos.
class _PhotosWrap extends StatelessWidget {
  const _PhotosWrap({
    required this.photos,
    required this.isUploading,
    required this.canAddMorePhotos,
    required this.deletingPhotoId,
    required this.onAddPhotosTap,
    required this.onPhotoTap,
    required this.onDeletePhotoTap,
  });

  final List<AscentPhoto> photos;
  final bool isUploading;
  final bool canAddMorePhotos;
  final int? deletingPhotoId;
  final Future<void> Function() onAddPhotosTap;
  final ValueChanged<AscentPhoto> onPhotoTap;
  final ValueChanged<AscentPhoto> onDeletePhotoTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final photo in photos)
          _AscentEditPhotoCard(
            photo: photo,
            isDeleting: deletingPhotoId == photo.id,
            onTap: () => onPhotoTap(photo),
            onDeleteTap: photo.isVerificationEvidence
                ? null
                : () => onDeletePhotoTap(photo),
          ),
        if (canAddMorePhotos)
          _AddPhotoTile(
            isUploading: isUploading,
            onTap: onAddPhotosTap,
          ),
      ],
    );
  }
}

// Aquesta tile afegeix més imatges sense crear un botó separat.
// Reprodueix el comportament de la selecció múltiple del registre d’ascensió.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.isUploading,
    required this.onTap,
  });

  final bool isUploading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isUploading ? null : onTap,
          child: Center(
            child: isUploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(
                    Icons.add_rounded,
                    size: 34,
                    color: Color(0xFF0B57D0),
                  ),
          ),
        ),
      ),
    );
  }
}

// Aquest indicador informa que les imatges s’estan pujant i associant.
// Es mostra tant en estat buit com dins la tile d’afegir.
class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
        SizedBox(height: 10),
        Text(
          'Pujant fotos...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

// Aquesta miniatura representa una foto existent de l’ascensió.
// Permet obrir-la en gran, eliminar-la i identificar si forma part de la verificació.
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
  final VoidCallback? onDeleteTap;

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
            if (photo.isVerificationEvidence)
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC7C3AED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Evidència',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
                          : Icon(
                              photo.isVerificationEvidence
                                  ? Icons.lock_rounded
                                  : Icons.close_rounded,
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