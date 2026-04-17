import 'package:flutter/material.dart';

// Aquest botó reutilitzable representa una acció secundària dins dels formularis.
// Serveix per mantenir el mateix estil visual a accions com tornar o canviar de flux.
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  // Aquest bloc defineix el text del botó, l’acció i si es pot utilitzar o no.
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  // Aquest mètode construeix el botó secundari amb el mateix estil arrodonit.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD9D9D9),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0B57D0),
          ),
        ),
      ),
    );
  }
}
