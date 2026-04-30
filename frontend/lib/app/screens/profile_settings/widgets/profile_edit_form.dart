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
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool showValidation;
  final bool isLoading;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

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
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Nom',
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
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Cognoms',
              errorText:
                  showValidation && lastNameController.text.trim().isEmpty
                      ? 'Els cognoms són obligatoris'
                      : null,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSave,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Desar canvis'),
            ),
          ),
        ],
      ),
    );
  }
}
