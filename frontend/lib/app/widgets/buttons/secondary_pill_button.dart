import 'package:flutter/material.dart';

// Aquest botó reutilitzable representa una acció secundària dins dels
// formularis (cancel·lar, tornar al login, tancar sessió...). Es presenta
// com un OutlinedButton perquè quedi clarament actiu però visualment menys
// destacat que el botó primari. Abans feia servir un fons gris clar que
// l'usuari confonia amb un estat deshabilitat.
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  // Color principal del botó. Mantenim el blau corporatiu per tornar el
  // botó coherent amb la resta de la UI.
  static const Color _accentColor = Color(0xFF0B57D0);

  // Aquest bloc defineix el text del botó, l’acció i si es pot utilitzar o no.
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _accentColor,
          side: const BorderSide(color: _accentColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
