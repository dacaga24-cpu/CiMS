import 'package:cims/app/screens/reset_password/reset_password_controller.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:cims/app/widgets/forms/app_form_card.dart';
import 'package:cims/app/widgets/forms/app_input_field.dart';
import 'package:cims/app/widgets/forms/form_error_text.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa la part principal del formulari de canvi de contrasenya.
// Serveix per reduir la mida de la pantalla i concentrar dins d’un sol component
// els camps, validacions i accions principals del procés.
class ResetPasswordFormCard extends StatelessWidget {
  const ResetPasswordFormCard({
    super.key,
    required this.controller,
  });

  // Aquest bloc rep el controlador de la pantalla per consultar l’estat
  // del formulari i executar les accions principals.
  final ResetPasswordController controller;

  // Aquest mètode construeix la targeta amb els camps de la nova contrasenya,
  // els errors de validació i els botons principals.
  @override
  Widget build(BuildContext context) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aquest bloc mostra el camp de la nova contrasenya
          // i permet a l’usuari veure-la o ocultar-la mentre l’escriu.
          const Text(
            'Contrasenya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: controller.passwordController,
            hintText: '••••••••••••',
            keyboardType: TextInputType.text,
            obscureText: controller.obscurePassword,
            onChanged: controller.onPasswordChanged,
            enabled: !controller.isLoading,
            suffixIcon: IconButton(
              onPressed: controller.isLoading
                  ? null
                  : controller.togglePasswordVisibility,
              icon: Icon(
                controller.obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6E6E73),
              ),
            ),
          ),
          // Aquest missatge indica que la nova contrasenya és obligatòria.
          if (controller.hasEmptyPassword) ...[
            const SizedBox(height: 10),
            const FormErrorText('La contrasenya és obligatòria'),
          ],
          // Aquest missatge informa que la contrasenya encara no compleix la longitud mínima.
          if (controller.hasShortPassword) ...[
            const SizedBox(height: 10),
            const FormErrorText(
              'La contrasenya ha de tenir almenys 8 caràcters',
            ),
          ],
          const SizedBox(height: 24),

          // Aquest bloc mostra el camp de confirmació per assegurar
          // que l’usuari ha escrit correctament la nova contrasenya.
          const Text(
            'Confirmar Contrasenya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: controller.confirmPasswordController,
            hintText: '••••••••••••',
            keyboardType: TextInputType.text,
            obscureText: controller.obscureConfirmPassword,
            onChanged: controller.onConfirmPasswordChanged,
            enabled: !controller.isLoading,
            suffixIcon: IconButton(
              onPressed: controller.isLoading
                  ? null
                  : controller.toggleConfirmPasswordVisibility,
              icon: Icon(
                controller.obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6E6E73),
              ),
            ),
          ),
          // Aquest missatge indica que cal confirmar també la nova contrasenya.
          if (controller.hasEmptyConfirmPassword) ...[
            const SizedBox(height: 10),
            const FormErrorText('Has de confirmar la contrasenya'),
          ],
          // Aquest missatge només es mostra quan les dues contrasenyes no coincideixen.
          if (controller.hasPasswordMismatch) ...[
            const SizedBox(height: 10),
            const FormErrorText(
              'Les contrasenyes han de coincidir',
              icon: Icons.error_outline,
            ),
          ],
          // Aquest bloc mostra un error general del procés de canvi de contrasenya.
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            FormErrorText(controller.errorMessage!),
          ],
          const SizedBox(height: 28),

          // Aquest botó inicia el procés de canvi de contrasenya.
          // Quan hi ha una operació en curs, es desactiva i mostra un indicador de càrrega.
          PrimaryGradientButton(
            label: 'Canviar contrasenya',
            icon: Icons.arrow_forward,
            isLoading: controller.isLoading,
            onPressed: () => controller.onChangePasswordTap(),
          ),
          const SizedBox(height: 16),

          // Aquest botó permet tornar al flux d’inici de sessió
          // si l’usuari decideix sortir d’aquesta pantalla.
          SecondaryPillButton(
            label: 'Tornar a l’inici de sessió',
            enabled: !controller.isLoading,
            onPressed: controller.onBackToLoginTap,
          ),
        ],
      ),
    );
  }
}
