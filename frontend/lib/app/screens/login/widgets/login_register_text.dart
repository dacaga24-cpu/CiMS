import 'package:flutter/material.dart';

// Aquest widget mostra el text inferior que dona accés al registre.
// Serveix per separar aquesta acció secundària del bloc principal del formulari.
class LoginRegisterPrompt extends StatelessWidget {
  const LoginRegisterPrompt({
    super.key,
    required this.onTap,
  });

  // Aquest bloc rep l’acció que s’ha d’executar quan l’usuari vol anar al registre.
  final VoidCallback onTap;

  // Aquest mètode construeix la fila inferior amb el text i l’accés al registre.
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Encara no tens un compte? ',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF3C3C43),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Registra\'t',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B57D0),
            ),
          ),
        ),
      ],
    );
  }
}
