import 'package:flutter/material.dart';

// Aquest text s’utilitza com a etiqueta dels camps del formulari.
// Centralitza l’estil perquè tots els camps mantinguin la mateixa aparença.
class RegisterFieldLabel extends StatelessWidget {
  const RegisterFieldLabel(
    this.text, {
    super.key,
  });

  // Text visible que identifica el camp del formulari.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E1E1E),
      ),
    );
  }
}
