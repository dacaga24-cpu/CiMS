import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra les accions finals del panell de filtres.
// Permet netejar la configuració actual o aplicar els filtres seleccionats.
class PeaksFiltersActions extends StatelessWidget {
  const PeaksFiltersActions({
    super.key,
    required this.onClear,
    required this.onApply,
    this.canApply = true,
  });

  // Aquestes accions es reben des del panell principal perquè la lògica
  // de netejar i aplicar filtres continuï centralitzada en un sol lloc.
  final Future<void> Function() onClear;
  final VoidCallback onApply;

  // Indica si els filtres actuals es poden aplicar.
  // Quan el rang d’altura no és vàlid, el botó queda visualment desactivat.
  final bool canApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryPillButton(
            label: 'Neteja',
            onPressed: onClear,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: canApply ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !canApply,
              child: PrimaryGradientButton(
                label: 'Aplica',
                onPressed: onApply,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
