import 'package:cims/app/screens/register/register_controller.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:flutter/material.dart';

// Aquest widget agrupa les accions principals del formulari de registre.
// Separa els botons dels camps per deixar el formulari principal més net.
class RegisterFormActions extends StatelessWidget {
  const RegisterFormActions({
    super.key,
    required this.controller,
  });

  // Controller que executa la creació del compte o el retorn al login.
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
    );
  }
}
