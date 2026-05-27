import 'package:flutter/material.dart';

// Aquest botó reutilitzable representa una acció secundària dins dels formularis.
// Es mostra com un OutlinedButton per quedar actiu, però amb menys pes visual que l’acció principal.
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  // Aquest color manté el botó alineat amb la identitat visual de l’aplicació.
  static const Color _accentColor = Color(0xFF0B57D0);

  // Aquestes dades defineixen el text del botó, l’acció i si es pot utilitzar.
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