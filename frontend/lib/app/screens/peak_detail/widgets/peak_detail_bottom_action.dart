import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra les accions fixes de la pantalla de detall.
// Permet registrar una nova ascensió o consultar l’historial del cim seleccionat.
class PeakDetailBottomAction extends StatelessWidget {
  const PeakDetailBottomAction({
    super.key,
    required this.onPressed,
    required this.onHistoryPressed,
  });

  // Aquestes accions es reben des del controller a través de la pantalla.
  // Així el widget manté només responsabilitat visual.
  final VoidCallback onPressed;
  final VoidCallback onHistoryPressed;

  // Aquest mètode construeix els botons inferiors de la pantalla.
  // Manté accessibles les accions principals sense barrejar navegació ni lògica de dades.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryGradientButton(
            label: 'Registrar ascensió',
            onPressed: onPressed,
          ),
          const SizedBox(height: 12),
          SecondaryPillButton(
            label: 'Historial ascensions',
            onPressed: onHistoryPressed,
          ),
        ],
      ),
    );
  }
}