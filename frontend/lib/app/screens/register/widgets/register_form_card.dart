import 'package:flutter/material.dart';

import '../../../widgets/buttons/primary_gradient_button.dart';
import '../../../widgets/buttons/secondary_pill_button.dart';
import '../../../widgets/forms/app_form_card.dart';
import '../../../widgets/forms/app_input_field.dart';
import '../../../widgets/forms/form_error_text.dart';
import '../register_controller.dart';

// Aquest widget agrupa la part principal del formulari de registre.
// Serveix per reduir la mida de la pantalla i concentrar dins d’un sol component
// els camps, validacions i accions principals relacionades amb la creació del compte.
class RegisterFormCard extends StatelessWidget {
  const RegisterFormCard({
    super.key,
    required this.controller,
  });

  // Aquest bloc rep el controlador del registre per consultar l’estat
  // del formulari i executar les accions principals.
  final RegisterController controller;

  // Aquest mètode construeix la targeta amb els camps del registre,
  // els errors de validació i els botons principals.
  @override
  Widget build(BuildContext context) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nom',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: controller.firstNameController,
            hintText: 'Nom',
            keyboardType: TextInputType.name,
            obscureText: false,
            onChanged: controller.onFirstNameChanged,
            enabled: !controller.isLoading,
          ),
          // Aquest missatge indica que el camp del nom encara no s’ha omplert.
          if (controller.hasEmptyFirstName) ...[
            const SizedBox(height: 10),
            const FormErrorText('El nom és obligatori'),
          ],
          const SizedBox(height: 24),
          const Text(
            'Cognom',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: controller.lastNameController,
            hintText: 'Cognom',
            keyboardType: TextInputType.name,
            obscureText: false,
            onChanged: controller.onLastNameChanged,
            enabled: !controller.isLoading,
          ),
          // Aquest missatge indica que el camp del cognom encara no s’ha omplert.
          if (controller.hasEmptyLastName) ...[
            const SizedBox(height: 10),
            const FormErrorText('El cognom és obligatori'),
          ],
          const SizedBox(height: 24),
          const Text(
            'Correu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: controller.emailController,
            hintText: 'Correu',
            keyboardType: TextInputType.emailAddress,
            obscureText: false,
            onChanged: controller.onEmailChanged,
            enabled: !controller.isLoading,
          ),
          // Aquest missatge indica que el correu és un camp obligatori.
          if (controller.hasEmptyEmail) ...[
            const SizedBox(height: 10),
            const FormErrorText('El correu és obligatori'),
          ],
          // Aquest missatge es mostra quan el correu no té un format correcte.
          if (controller.hasInvalidEmail) ...[
            const SizedBox(height: 10),
            const FormErrorText('Introdueix un correu electrònic vàlid'),
          ],
          const SizedBox(height: 24),
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
          // Aquest bloc mostra un error general del procés de registre.
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            FormErrorText(controller.errorMessage!),
          ],
          const SizedBox(height: 28),
          // Aquest botó inicia el procés de creació del compte amb les dades del formulari.
          // Quan hi ha una operació en curs, es desactiva i mostra un indicador de càrrega.
          PrimaryGradientButton(
            label: 'Crear compte',
            icon: Icons.arrow_forward,
            isLoading: controller.isLoading,
            onPressed: () => controller.onCreateAccountTap(),
          ),
          const SizedBox(height: 16),
          // Aquest botó permet tornar a la pantalla d’accés
          // si l’usuari ja disposa d’un compte.
          SecondaryPillButton(
            label: 'Ja tinc un compte',
            enabled: !controller.isLoading,
            onPressed: controller.onAlreadyHaveAccountTap,
          ),
        ],
      ),
    );
  }
}
