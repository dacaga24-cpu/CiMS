import 'package:flutter/material.dart';

// Aquest widget mostra el formulari de canvi de contrasenya.
// La validació principal es manté al controller, però aquí es mostren els errors visuals.
class ProfilePasswordForm extends StatelessWidget {
  const ProfilePasswordForm({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.showValidation,
    required this.isLoading,
    required this.onChanged,
    required this.onSave,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool showValidation;
  final bool isLoading;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

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
            'Canviar contrasenya',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: currentPasswordController,
            enabled: !isLoading,
            obscureText: true,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Contrasenya actual',
              errorText: showValidation &&
                      currentPasswordController.text.trim().isEmpty
                  ? 'La contrasenya actual és obligatòria'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: newPasswordController,
            enabled: !isLoading,
            obscureText: true,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Nova contrasenya',
              errorText: showValidation && newPassword.length < 6
                  ? 'La nova contrasenya ha de tenir mínim 6 caràcters'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirmPasswordController,
            enabled: !isLoading,
            obscureText: true,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Confirmar nova contrasenya',
              errorText: showValidation && newPassword != confirmPassword
                  ? 'Les contrasenyes no coincideixen'
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
                  : const Text('Actualitzar contrasenya'),
            ),
          ),
        ],
      ),
    );
  }
}
