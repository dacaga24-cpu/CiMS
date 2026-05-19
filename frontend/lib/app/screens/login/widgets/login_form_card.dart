import 'package:cims/app/screens/login/login_controller.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/forms/app_form_card.dart';
import 'package:cims/app/widgets/forms/app_input_field.dart';
import 'package:cims/app/widgets/forms/form_error_text.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa la part principal del formulari de login.
// Serveix per treure pes visual de la pantalla i deixar clar
// quin bloc correspon a la captura de dades i a l’acció principal.
class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.controller,
  });

  // Aquest bloc rep el controlador del login per llegir l’estat actual
  // del formulari i executar les accions necessàries.
  final LoginController controller;

  // Aquest mètode construeix la targeta amb els camps principals,
  // els missatges d’error i el botó d’inici de sessió.
  @override
  Widget build(BuildContext context) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aquest bloc mostra l’etiqueta i el camp del correu electrònic,
          // que és una de les dades necessàries per autenticar l’usuari.
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
            hintText: 'elteu@correu.com',
            keyboardType: TextInputType.emailAddress,
            obscureText: false,
            enabled: !controller.isLoading,
            onChanged: controller.onEmailChanged,
          ),
          // Aquests missatges cobreixen tant el cas de correu buit (només
          // rellevant en el flux "Has oblidat la contrasenya?") com el de
          // format incorrecte.
          if (controller.hasEmptyEmail) ...[
            const SizedBox(height: 8),
            const FormErrorText('Has d\'introduir un correu vàlid'),
          ] else if (controller.hasInvalidEmail) ...[
            const SizedBox(height: 8),
            const FormErrorText('Introdueix un correu electrònic vàlid'),
          ],
          const SizedBox(height: 26),

          // Aquest bloc mostra el camp de contrasenya
          // i l’accés a la recuperació de contrasenya.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Contrasenya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              // Aquest accés permet iniciar el flux de recuperació de contrasenya
              // utilitzant el correu que l’usuari ja hagi escrit al formulari.
              GestureDetector(
                onTap: controller.isLoading
                    ? null
                    : controller.onForgotPasswordTap,
                child: Text(
                  'Has oblidat la contrasenya?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: controller.isLoading
                        ? const Color(0xFF9AA0A6)
                        : const Color(0xFF0B57D0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppInputField(
            controller: controller.passwordController,
            hintText: '••••••••••••',
            keyboardType: TextInputType.text,
            obscureText: controller.obscurePassword,
            enabled: !controller.isLoading,
            onChanged: controller.onPasswordChanged,
            onSubmitted: (_) => controller.onLoginTap(),
            // Aquesta icona permet a l’usuari comprovar la contrasenya escrita
            // sense sortir del camp ni alterar la resta del formulari.
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

          // Aquest missatge informa que la contrasenya és obligatòria.
          if (controller.hasEmptyPassword) ...[
            const SizedBox(height: 8),
            const FormErrorText('La contrasenya és obligatòria'),
          ],

          // Aquest bloc mostra un error general del procés de login
          // o de la recuperació de contrasenya.
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 12),
            FormErrorText(controller.errorMessage!),
          ],

          // Aquest missatge confirma de manera neutra que s’ha iniciat
          // el procés de recuperació de contrasenya.
          if (controller.infoMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.infoMessage!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B57D0),
              ),
            ),
          ],

          const SizedBox(height: 34),

          // Aquest botó inicia el procés d’autenticació.
          // Quan hi ha una petició en curs, es desactiva i mostra un indicador de càrrega.
          PrimaryGradientButton(
            label: 'Iniciar Sessió',
            isLoading: controller.isLoading,
            onPressed: () => controller.onLoginTap(),
          ),
        ],
      ),
    );
  }
}
