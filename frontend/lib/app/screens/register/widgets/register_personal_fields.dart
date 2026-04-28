import 'package:cims/app/screens/register/register_controller.dart';
import 'package:cims/app/screens/register/widgets/register_field_label.dart';
import 'package:cims/app/widgets/forms/app_input_field.dart';
import 'package:cims/app/widgets/forms/form_error_text.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa els camps de dades personals del registre.
// Manté junts el nom i el cognom perquè formen part del mateix bloc funcional.
class RegisterPersonalFields extends StatelessWidget {
  const RegisterPersonalFields({
    super.key,
    required this.controller,
  });

  // Controller que proporciona l’estat dels camps i les validacions visuals.
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aquest bloc mostra el camp del nom, que forma part
        // de la informació bàsica necessària per crear el compte.
        const RegisterFieldLabel('Nom'),
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

        // Aquest bloc mostra el camp del cognom, necessari
        // per completar les dades personals mínimes del registre.
        const RegisterFieldLabel('Cognom'),
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
      ],
    );
  }
}
