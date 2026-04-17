import 'package:flutter/material.dart';

// Aquest widget reutilitzable mostra un missatge d’error simple amb l’estil habitual.
// Serveix per evitar repetir el mateix Text d’error a diferents formularis.
class FormErrorText extends StatelessWidget {
  const FormErrorText(
    this.message, {
    super.key,
    this.icon,
  });

  // Aquest bloc defineix el missatge que s’ha de mostrar i, opcionalment,
  // una icona per reforçar visualment l’avís.
  final String message;
  final IconData? icon;

  // Aquest mètode construeix el missatge d’error amb o sense icona.
  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD93025),
        ),
      );
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFFD93025),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD93025),
            ),
          ),
        ),
      ],
    );
  }
}
