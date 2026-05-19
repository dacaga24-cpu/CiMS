import 'package:flutter/material.dart';

// Aquest widget mostra l’estat d’error del catàleg.
// També ofereix una acció directa per tornar a carregar les dades.
class PeaksErrorState extends StatelessWidget {
  const PeaksErrorState({
    super.key,
    required this.message,
    required this.onRetryTap,
  });

  // Aquestes propietats reben el missatge d’error i l’acció de reintent
  // perquè la pantalla pugui recuperar-se sense sortir del catàleg.
  final String message;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFF9AA3B2),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetryTap,
              child: const Text('Torna-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
