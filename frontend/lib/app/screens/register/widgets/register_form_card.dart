import 'package:cims/app/screens/register/register_controller.dart';
import 'package:cims/app/screens/register/widgets/register_email_field.dart';
import 'package:cims/app/screens/register/widgets/register_form_actions.dart';
import 'package:cims/app/screens/register/widgets/register_password_fields.dart';
import 'package:cims/app/screens/register/widgets/register_personal_fields.dart';
import 'package:cims/app/widgets/forms/app_form_card.dart';
import 'package:cims/app/widgets/forms/form_error_text.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa la part principal del formulari de registre.
// Serveix com a contenidor visual i delega cada bloc del formulari
// a widgets més petits per mantenir el fitxer llegible.
class RegisterFormCard extends StatelessWidget {
  const RegisterFormCard({
    super.key,
    required this.controller,
  });

  // Aquest bloc rep el controlador del registre per consultar l’estat
  // del formulari i executar les accions principals.
  final RegisterController controller;

  // Aquest mètode construeix la targeta general del registre.
  // Els camps, les validacions visuals i les accions queden separats per blocs.
  @override
  Widget build(BuildContext context) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegisterPersonalFields(controller: controller),
          const SizedBox(height: 24),
          RegisterEmailField(controller: controller),
          const SizedBox(height: 24),
          RegisterPasswordFields(controller: controller),

          // Aquest bloc mostra un error general del procés de registre.
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            FormErrorText(controller.errorMessage!),
          ],

          const SizedBox(height: 28),
          RegisterFormActions(controller: controller),
        ],
      ),
    );
  }
}
