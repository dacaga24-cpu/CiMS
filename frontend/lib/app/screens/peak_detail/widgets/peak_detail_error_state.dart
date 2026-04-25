import 'package:flutter/material.dart';

// Aquest widget mostra un error dins de la pantalla de detall.
// Si rep una acció de reintent, també mostra un botó per tornar a carregar les dades.
class PeakDetailErrorState extends StatelessWidget {
  const PeakDetailErrorState({
    super.key,
    required this.message,
    this.onRetryTap,
  });

  // Aquestes propietats permeten mostrar el missatge d’error
  // i, opcionalment, oferir una acció per recuperar la pantalla.
  final String message;
  final Future<void> Function()? onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFF9AA3B2),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4B5563),
              ),
            ),
            if (onRetryTap != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onRetryTap,
                child: const Text('Torna-ho a provar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}