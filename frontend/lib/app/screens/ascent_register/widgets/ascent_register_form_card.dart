import 'package:cims/app/screens/ascent_register/ascent_register_controller.dart';
import 'package:cims/app/screens/ascent_register/widgets/ascent_register_photo_card.dart';
import 'package:cims/app/widgets/forms/app_form_card.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa el formulari principal de la pantalla.
// Manté la screen lleugera i concentra en un sol bloc els camps visuals del registre.
class AscentRegisterFormCard extends StatelessWidget {
  const AscentRegisterFormCard({
    super.key,
    required this.controller,
    required this.onDateTap,
  });

  // Aquest controller aporta l’estat actual del formulari,
  // com la data seleccionada, les notes i les fotos temporals.
  final AscentRegisterController controller;

  // Aquesta acció permet obrir el selector de data
  // des del mateix bloc del formulari.
  final VoidCallback onDateTap;

  // Aquest bloc reuneix els camps principals del registre
  // dins d’una mateixa targeta per fer el formulari més clar i ordenat.
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
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Pujar foto'),
          const SizedBox(height: 10),
          AscentRegisterPhotoCard(
            previewBytes: controller.selectedPhotoPreviewBytes,
            isLoading: controller.isUploadingPhoto,
            canAddMorePhotos: controller.canAddMorePhotos,
            selectedPhotosCount: controller.selectedPhotosCount,
            maxPhotos: controller.maxAscentPhotos,
            errorMessage: controller.photoErrorMessage,
            onTap: controller.onPhotoTap,
            onRemoveTap: controller.onRemovePhotoTap,
          ),
        ],
      ),
    );
  }
}

// Aquest text s’utilitza com a capçalera visual de cada bloc del formulari.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  // Aquest text identifica de manera clara cada secció
  // perquè el formulari sigui més fàcil de recórrer.
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

// Aquest camp visual mostra la data seleccionada o un text d’ajuda.
// També permet netejar la data perquè l’ascensió pugui registrar-se sense dia concret.
class _DateSelectorField extends StatelessWidget {
  const _DateSelectorField({
    required this.value,
    required this.hasValue,
    required this.onTap,
    required this.onClearTap,
  });

  // Aquest valor mostra la data o el text inicial del camp.
  final String value;

  // Indica si actualment hi ha una data seleccionada.
  final bool hasValue;

  // Aquesta acció delega a la pantalla l’obertura del calendari.
  final VoidCallback onTap;

  // Aquesta acció permet deixar el registre sense data.
  final VoidCallback onClearTap;

  // Aquest camp no deixa escriure directament, sinó que guia l’usuari
  // a seleccionar o netejar la data amb controls visuals simples.
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

// Aquest camp recull les notes lliures de l’usuari.
// Està pensat per deixar espai suficient a observacions i sensacions de la sortida.
class _NotesField extends StatelessWidget {
  const _NotesField({
    required this.controller,
  });

  // Aquest controlador manté el text escrit per l’usuari
  // perquè es pugui conservar dins del formulari.
  final TextEditingController controller;

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
