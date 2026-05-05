import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:flutter/material.dart';

// Aquest formulari demana la contrasenya actual abans de desactivar el compte.
// Serveix per confirmar una acció sensible i evitar desactivacions accidentals.
class ProfileDeleteAccountForm extends StatelessWidget {
  const ProfileDeleteAccountForm({
    super.key,
    required this.passwordController,
    required this.showValidation,
    required this.isLoading,
    required this.onChanged,
    required this.onCancel,
    required this.onDelete,
  });

  final TextEditingController passwordController;
  final bool showValidation;
  final bool isLoading;
  final VoidCallback onChanged;
  final VoidCallback onCancel;
  final Future<void> Function() onDelete;

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
            'Desactivar compte',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Introdueix la teva contrasenya actual per confirmar aquesta acció.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF5F6368),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: true,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: 'Contrasenya actual',
              errorText:
                  showValidation && passwordController.text.trim().isEmpty
                      ? 'La contrasenya és obligatòria'
                      : null,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Desactivar compte',
            isLoading: isLoading,
            onPressed: isLoading
                ? null
                : () {
                    onDelete();
                  },
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
