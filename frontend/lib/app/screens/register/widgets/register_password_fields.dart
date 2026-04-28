import 'package:cims/app/screens/register/register_controller.dart';
import 'package:cims/app/screens/register/widgets/register_field_label.dart';
import 'package:cims/app/widgets/forms/app_input_field.dart';
import 'package:cims/app/widgets/forms/form_error_text.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa els camps de contrasenya del registre.
// Manté juntes la contrasenya i la seva confirmació perquè comparteixen validacions.
class RegisterPasswordFields extends StatelessWidget {
  const RegisterPasswordFields({
    super.key,
    required this.controller,
  });

  // Controller que gestiona la visibilitat, els valors i les validacions de contrasenya.
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aquest bloc mostra el camp de contrasenya
        // i permet a l’usuari decidir si la vol veure o ocultar mentre escriu.
        const RegisterFieldLabel('Contrasenya'),
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
        // Aquest missatge indica que la contrasenya és obligatòria.
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

        // Aquest bloc mostra el camp de confirmació perquè l’usuari
        // pugui verificar que ha escrit correctament la contrasenya desitjada.
        const RegisterFieldLabel('Confirmar Contrasenya'),
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
        // Aquest missatge indica que cal omplir també la confirmació de contrasenya.
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
      ],
    );
  }
}
