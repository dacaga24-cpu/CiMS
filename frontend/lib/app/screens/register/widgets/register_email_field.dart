import 'package:cims/app/screens/register/register_controller.dart';
import 'package:cims/app/screens/register/widgets/register_field_label.dart';
import 'package:cims/app/widgets/forms/app_input_field.dart';
import 'package:cims/app/widgets/forms/form_error_text.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra el camp del correu electrònic del registre.
// També concentra els missatges visuals associats al format i obligatorietat.
class RegisterEmailField extends StatelessWidget {
  const RegisterEmailField({
    super.key,
    required this.controller,
  });

  // Controller que exposa el valor del correu i el seu estat de validació.
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aquest bloc mostra el camp del correu electrònic,
        // que servirà com a dada d’accés i identificació de l’usuari.
        const RegisterFieldLabel('Correu'),
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
      ],
    );
  }
}
