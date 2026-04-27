import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra l’acció principal fixa de la pantalla de detall.
// Permet iniciar el registre d’una ascensió del cim seleccionat.
class PeakDetailBottomAction extends StatelessWidget {
  const PeakDetailBottomAction({
    super.key,
    required this.onPressed,
  });

  // Aquesta acció es rep des del controller a través de la pantalla.
  // Manté el botó desacoblat de la lògica de navegació.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PrimaryGradientButton(
        label: 'Registrar ascensió',
        icon: Icons.north_east_rounded,
        onPressed: onPressed,
      ),
    );
  }
}