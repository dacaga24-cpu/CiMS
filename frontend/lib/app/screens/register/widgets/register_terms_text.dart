import 'package:flutter/material.dart';

// Aquest widget mostra l’avís legal bàsic del registre.
// Serveix per separar aquest text auxiliar del formulari principal
// i deixar la pantalla de registre més neta.
class RegisterTermsText extends StatelessWidget {
  const RegisterTermsText({
    super.key,
    required this.isLoading,
    required this.onTapTerms,
  });

  // Aquest bloc rep l’estat de càrrega i l’acció relacionada amb els termes del servei.
  final bool isLoading;
  final VoidCallback onTapTerms;

  // Aquest mètode construeix el text informatiu inferior del registre.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'En registrar-te, acceptes els nostres ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF3C3C43),
            ),
          ),
          GestureDetector(
            onTap: isLoading ? null : onTapTerms,
            child: const Text(
              'Termes de Servei',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B57D0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
