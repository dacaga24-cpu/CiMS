import 'package:cims/app/theme/app_theme.dart';
import 'package:cims/app/widgets/buttons/destructive_pill_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:cims/app/widgets/forms/password_text_field.dart';
import 'package:flutter/material.dart';

// Aquest formulari confirma la desactivació del compte.
// Demana la contrasenya actual perquè és una acció sensible.
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

  // Aquestes dades controlen el camp de contrasenya, la validació i les accions del formulari.
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
          const SizedBox(height: 12),
          // Aquest avís explica la conseqüència principal de l’acció.
          // Ajuda l’usuari a confirmar la decisió abans d’introduir la contrasenya.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.dangerColor.withValues(alpha: 0.35),
              ),
            ),
            child: const Text(
              'Aquesta acció desactivarà el teu compte i deixaràs de tenir '
              'accés a les ascensions i fotos registrades. Introdueix la '
              'contrasenya actual per confirmar.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF8A2A2A),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          PasswordTextField(
            controller: passwordController,
            labelText: 'Contrasenya actual',
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            errorText: showValidation && passwordController.text.trim().isEmpty
                ? 'La contrasenya és obligatòria'
                : null,
          ),
          const SizedBox(height: 24),
          DestructivePillButton(
            label: 'Desactivar compte',
            isLoading: isLoading,
            onPressed: isLoading ? null : onDelete,
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