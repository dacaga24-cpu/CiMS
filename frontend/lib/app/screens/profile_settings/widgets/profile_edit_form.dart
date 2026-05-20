import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:cims/core/util/validation.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el formulari d’edició de dades personals.
// Rep els controladors i accions des de fora per mantenir separada la UI de la lògica.
class ProfileEditForm extends StatelessWidget {
  const ProfileEditForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.showValidation,
    required this.isLoading,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool showValidation;
  final bool isLoading;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dades personals',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: firstNameController,
            enabled: !isLoading,
            maxLength: kMaxUserNameLength,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Nom',
              // Amaguem el comptador integrat per no afegir soroll visual a
              // sota el camp. El límit dur ja s'aplica via maxLength.
              counterText: '',
              errorText:
                  showValidation && firstNameController.text.trim().isEmpty
                      ? 'El nom és obligatori'
                      : null,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: lastNameController,
            enabled: !isLoading,
            maxLength: kMaxUserNameLength,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Cognoms',
              counterText: '',
              errorText:
                  showValidation && lastNameController.text.trim().isEmpty
                      ? 'Els cognoms són obligatoris'
                      : null,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Desar canvis',
            isLoading: isLoading,
            onPressed: isLoading ? null : onSave,
          ),
          const SizedBox(height: 12),
          SecondaryPillButton(
            label: 'Cancel·lar',
            enabled: !isLoading,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
